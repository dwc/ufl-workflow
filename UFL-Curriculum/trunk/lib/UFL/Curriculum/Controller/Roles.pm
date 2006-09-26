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

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
