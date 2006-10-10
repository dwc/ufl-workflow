package UFL::Workflow::Controller::Groups;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

=head1 NAME

UFL::Workflow::Controller::Groups - Groups controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing groups.

=head1 METHODS

=head2 index 

Display a list of current groups.

=cut

sub index : Path('') Args(0) {
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
            my $group = $c->model('DBIC::Group')->find_or_create({
                name => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $group->uri_args ]));
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

=head2 edit

Edit the stashed group.

=cut

sub edit : PathPart Chained('group') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $group = $c->stash->{group};

            my $values = $result->valid;
            foreach my $key (keys %$values) {
                $group->$key($values->{$key}) if $group->can($key);
            }

            # TODO: Unique check
            $group->update;

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $group->uri_args ]));
        }
    }

    $c->stash(template => 'groups/edit.tt');
}

=head2 add_role

Add a role to the stashed group.

=cut

sub add_role : PathPart Chained('group') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $group = $c->stash->{group};

            my $role = $group->roles->find_or_create({
                name => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $group->uri_args ]));
        }
    }

    $c->stash(template => 'groups/add_role.tt');
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
