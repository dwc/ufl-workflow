package UFL::Workflow::Controller::Users;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

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

    my $users = $c->model('DBIC::User')->search(undef, { order_by => 'username' });

    $c->stash(
        users    => $users,
        template => 'users/index.tt'
    );
}

=head2 add

Add a new user.

=cut

sub add : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $user = $c->model('DBIC::User')->find_or_create({
                username => $result->valid('username'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $user->uri_args ]));
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

    $c->stash(user => $user);
}

=head2 view

Display basic information on the stashed user.

=cut

sub view : PathPart('') Chained('user') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'users/view.tt');
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

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $user->uri_args ]));
        }
    }

    my $groups = $c->model('DBIC::Group')->root_groups;

    if (my $group_id = $c->req->param('group_id')) {
        $group_id =~ s/\D//g;
        $c->detach('/default') unless $group_id;

        my $group = $c->model('DBIC::Group')->find($group_id);
        $c->detach('/default') unless $group;

        my $roles = $c->model('DBIC::Role')->search(
            { 'group_roles.group_id' => $group->id },
            { join => 'group_roles' },
        );

        $c->stash(
            group => $group,
            roles => $roles,
        );
    }

    $c->stash(
        groups   => $groups,
        template => 'users/add_group_role.tt'
    );
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

    return $c->res->redirect($c->uri_for($self->action_for('view'), [ $user->uri_args ]));
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
