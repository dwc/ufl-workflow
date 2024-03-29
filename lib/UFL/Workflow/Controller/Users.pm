package UFL::Workflow::Controller::Users;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;
use UFL::Workflow::Util;

__PACKAGE__->mk_accessors(qw/ldap_username_field ldap_search_fields/);

__PACKAGE__->config(
    ldap_username_field => 'uid',
    ldap_search_fields  => [ qw/uid/ ],
);

=head1 NAME

UFL::Workflow::Controller::Users - Users controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing users.

=head1 METHODS

=head2 index

Display a list of current users.

=cut

sub index : Path('') Args(0) {
    my ($self, $c) = @_;

    my $field = 'display_name';
    my $letter = $c->req->query_parameters->{letter} || 'a';
    my $query = $c->req->query_parameters->{query};
    my $results;

    my $users = $c->model('DBIC::User')->search(
        { "LOWER($field)" => { 'like', $letter . '%'  } },
        { order_by => $field },
    );

    if ($query) {
        $query = UFL::Workflow::Util::strip_ufid_hyphen($query);

        $results = $c->model('DBIC::User')->search(
            {
                -or => [
                     "LOWER($field)" => { 'like', '%' . lc($query) . '%' },
                     "username"      => { like => '%' . $query . '%' },
                ],
            },
            { order_by => $field },
        );

        $letter = substr($query, 0, 1);
        $users = $c->model('DBIC::User')->search(
            { "LOWER($field)" => { 'like', $letter . '%'  } },
            { order_by => $field },
        );
    }

    $c->stash(
        letter   => $letter,
        query    => $query,
        results  => $results,
        template => 'users/index.tt',
        users    => $users,
    );
}

=head2 add

Add one or more new users.

=cut

sub add : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my @new_users = split /[ \r\n]+/, lc $result->valid('users');

            my (@added_users, @existing_users, @invalid_users);
            foreach my $new_user (@new_users) {
                $new_user = UFL::Workflow::Util::strip_ufid_hyphen($new_user);

                my $filter = $self->_ldap_filter($new_user);
                my $mesg = $c->model('LDAP')->search($filter);
                my $entry = $mesg->shift_entry;

                my $field = $self->ldap_username_field;
                if ($entry and $entry->exists($field)) {
                    if (my $user = $c->model('DBIC::User')->find({ username => $entry->$field })) {
                        push @existing_users, $user;
                    }
                    else {
                        my $user = $c->model('DBIC::User')->from_ldap_entry($entry, $field);
                        $user->insert;

                        push @added_users, $user;
                    }
                }
                else { 
                    push @invalid_users, $new_user;
                }
            }

            $c->stash(
                added_users    => [ @added_users ],
                existing_users => [ @existing_users ],
                invalid_users  => [ @invalid_users ],
            );
        }
    }

    $c->stash(template => 'users/add.tt');
}

=head2 user

Fetch the specified user.

=cut

sub user : PathPart('users') Chained('/') CaptureArgs(1) {
    my ($self, $c, $username) = @_;

    my $user = $c->model('DBIC::User')->find({ username => $username });
    $c->detach('/default') unless $user;
    $c->detach('/forbidden') unless $c->user->username eq $user->username
        or $c->check_any_user_role('Administrator', 'Help Desk');

    $c->stash(user => $user);
}

=head2 view

Display basic information on the stashed user.

=cut

sub view : PathPart('') Chained('user') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'users/view.tt');
}

=head2 edit

Edit the stashed user.

=cut

sub edit : PathPart Chained('user') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $user = $c->stash->{user};

            $user->update({
                username     => $result->valid('username'),
                display_name => $result->valid('display_name'),
                email        => $result->valid('email'),
                wants_email  => $result->valid('wants_email') ? 1 : 0,
                active       => $result->valid('active') ? 1 : 0,
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $user->uri_args));
        }
    }

    $c->stash(template => 'users/edit.tt');
}

=head2 toggle_email

Toggle whether the stashed user wants to receive email or not. This is
an action that users can perform themselves.

=cut

sub toggle_email : PathPart Chained('user') Args(0) {
    my ($self, $c) = @_;

    my $user = $c->stash->{user};

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            $user->update({
                wants_email => $result->valid('wants_email') ? 1 : 0,
            });
        }
    }

    $c->res->redirect($c->uri_for($self->action_for('view'), $user->uri_args));
}

=head2 add_group_role

Add the stashed user to the specified group-role.

=cut

sub add_group_role : PathPart Chained('user') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $group_role = $c->model('DBIC::GroupRole')->find({
                group_id => $result->valid('group_id'),
                role_id  => $result->valid('role_id'),
            });
            $c->detach('/default') unless $group_role;

            my $user = $c->stash->{user};
            $user->add_to_group_roles($group_role) unless $user->has_group_role($group_role);

            return $c->res->redirect($c->uri_for($self->action_for('view'), $user->uri_args));
        }
    }

    my $groups = $c->model('DBIC::Group')->root_groups;

    # Show the roles once a group is selected
    if (my $group_id = $c->req->param('group_id')) {
        $group_id =~ s/\D//g;
        $c->detach('/default') unless $group_id;

        my $group = $c->model('DBIC::Group')->find($group_id);
        $c->detach('/default') unless $group;

        $c->stash(group => $group);
    }

    $c->stash(
        groups   => $groups,
        template => 'users/add_group_role.tt',
    );
}

=head2 list_group_roles

List roles that are valid for the user, and the specified
group via L<JSON>.

=cut

sub list_group_roles : PathPart Chained('user') Args(0) {
    my ($self, $c) = @_;
   
    # Show the roles once a group is selected
    if (my $group_id = $c->req->param('group_id')) {
        $group_id =~ s/\D//g;
        $c->detach('/default') unless $group_id;

        my $group = $c->model('DBIC::Group')->find($group_id);
        $c->detach('/default') unless $group;

        my @roles = $group->roles;
        $c->stash(roles => [ map { $_->to_json } @roles ]);
    }

    my $view = $c->view('JSON');
    $view->expose_stash([ qw/roles/ ]);
    $c->forward($view);
}

=head2 delete_group_role

Remove the stashed user from the specified group-role.

=cut

sub delete_group_role : PathPart Chained('user') Args(0) {
    my ($self, $c) = @_;

    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $user = $c->stash->{user};

    my $result = $self->validate_form($c);
    if ($result->success) {
        my $group_role = $c->model('DBIC::GroupRole')->find({
            group_id => $result->valid('group_id'),
            role_id  => $result->valid('role_id'),
        });
        $c->detach('/default') unless $group_role;

        $user->remove_from_group_roles($group_role);
    }

    return $c->res->redirect($c->uri_for($self->action_for('view'), $user->uri_args));
}

=head2 _ldap_filter

Based on the configured LDAP search fields, return a filter string.

=cut

sub _ldap_filter {
    my ($self, $query) = @_;

    my $filter = join '', map { "($_=$query)" } @{ $self->ldap_search_fields };
    $filter = "(|$filter)";
    warn "filter = [$filter]";

    return $filter;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
