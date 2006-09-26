package UFL::Curriculum::Controller::Users;

use strict;
use warnings;
use base qw/UFL::Curriculum::BaseController/;

=head1 NAME

UFL::Curriculum::Controller::Users - Users controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing users.

=head1 METHODS

=head2 index

Display a list of current users.

=cut

sub index : Path Args(0) {
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

=head2 add_role

Add the stashed user to the specified role.

=cut

sub add_role : PathPart Chained('user') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $role = $c->model('DBIC::Role')->find($result->valid('role_id'));
            $c->detach('/default') unless $role;

            my $user = $c->stash->{user};
            $user->add_to_roles($role) unless $user->has_role($role);

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $user->uri_args ]));
        }
    }

    my $roles = $c->model('DBIC::Role')->search(undef, { order_by => 'name' });

    $c->stash(
        roles    => $roles,
        template => 'users/add_role.tt'
    );
}

=head2 delete_role

Remove the stashed user from the specified role.

=cut

sub delete_role : PathPart Chained('user') Args(0) {
    my ($self, $c) = @_;

    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $user = $c->stash->{user};

    my $result = $self->validate_form($c);
    if ($result->success) {
        my $role = $c->model('DBIC::Role')->find($result->valid('role_id'));
        $c->detach('/default') unless $role;

        $user->remove_from_roles($role);
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
