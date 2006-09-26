package UFL::Curriculum::Controller::Groups;

use strict;
use warnings;
use base qw/UFL::Curriculum::BaseController/;

=head1 NAME

UFL::Curriculum::Controller::Groups - Groups controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing groups.

=head1 METHODS

=head2 index 

Display a list of current groups.

=cut

sub index : Path Args(0) {
    my ($self, $c) = @_;

    my $groups = $c->model('DBIC::Group')->search(undef, { order_by => 'name' });

    $c->stash(
        groups   => $groups,
        template => 'groups/index.tt',
    );
}

=head2 add

Add a new group.

=cut

sub add : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);

        if ($result->success) {
            my $user = $c->model('DBIC::Group')->find_or_create({
                name => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $user->uri_args ]));
        }
    }

    $c->stash(template => 'groups/add.tt');
}

=head2 group

Fetch the specified group.

=cut

sub group : PathPart('groups') Chained('/') CaptureArgs(1) {
    my ($self, $c, $group_id) = @_;

    my $group = $c->model('DBIC::Group')->find($group_id);
    $c->detach('/default') unless $group;

    $c->stash(group => $group);
}

=head2 view

Display basic information on the stashed group.

=cut

sub view : PathPart('') Chained('group') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'groups/view.tt');
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
