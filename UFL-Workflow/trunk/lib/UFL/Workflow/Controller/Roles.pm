package UFL::Workflow::Controller::Roles;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

=head1 NAME

UFL::Workflow::Controller::Roles - Roles controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing roles.

=head1 METHODS

=head2 role

Fetch the specified role.

=cut

sub role : PathPart('roles') Chained('/') CaptureArgs(1) {
    my ($self, $c, $role_id) = @_;

    my $role = $c->model('DBIC::Role')->find($role_id);
    $c->detach('/default') unless $role;

    $c->stash(role => $role);
}

=head2 view

Display basic information on the stashed role.

=cut

sub view : PathPart('') Chained('role') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'roles/view.tt');
}

=head2 edit

Edit the stashed role.

=cut

sub edit : PathPart Chained('role') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $role = $c->stash->{role};
            $role->update({
                name => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $role->uri_args));
        }
    }

    $c->stash(template => 'roles/edit.tt');
}

=head2 add_user

Add a user to the stashed role.

=cut

sub add_user : PathPart Chained('role') Args(0) {
    my ($self, $c) = @_;

    my $role = $c->stash->{role};

    my $users  = $c->model('DBIC::User')->search(undef, { order_by => 'username' });
    my $groups = $c->model('DBIC::Group')->search(
        { 'group_roles.role_id' => $role->id },
        { join => 'group_roles' },
    );

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $user  = $users->find($result->valid('user_id'));
            my $group = $groups->find($result->valid('group_id'));
            $c->detach('/default') unless $user and $group;

            $user->user_group_roles->find_or_create({
                group_id => $group->id,
                role_id  => $role->id,
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $role->uri_args));
        }
    }

    $c->stash(
        users    => $users,
        groups   => $groups,
        template => 'roles/add_user.tt',
    );
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
