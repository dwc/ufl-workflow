package UFL::Curriculum::Controller::Roles;

use strict;
use warnings;
use base qw/UFL::Curriculum::BaseController/;

=head1 NAME

UFL::Curriculum::Controller::Roles - Roles controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

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

            my $values = $result->valid;
            foreach my $key (keys %$values) {
                $role->$key($values->{$key}) if $role->can($key);
            }

            # TODO: Unique check
            $role->update;

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $role->uri_args ]));
        }
    }

    $c->stash(template => 'roles/edit.tt');
}

=head2 add_users

Add users to the stashed role.

=cut

sub add_users : PathPart Chained('role') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $role = $c->stash->{role};

            my @usernames = split /\s+/, $result->valid('usernames');
            my %seen_usernames;
            foreach my $username (@usernames) {
                next if $seen_usernames{$username}++;

                my $user = $c->model('DBIC::User')->find_or_create({
                    username => $username,
                });

                $role->add_to_users($user) unless $user->has_role($role);
            }

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $role->uri_args ]));
        }
    }

    $c->stash(template => 'roles/add_users.tt');
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;