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

    my $groups = $c->model('DBIC::Group')->root_groups;

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
            my $group = $c->model('DBIC::Group')->create({
                parent_group_id => $result->valid('parent_group_id') || undef,
                name            => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $group->uri_args));
        }
    }

    my $groups = $c->model('DBIC::Group')->root_groups;

    $c->stash(
        groups   => $groups,
        template => 'groups/add.tt',
    );
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
            $group->update({
                parent_group_id => $result->valid('parent_group_id') || undef,
                name            => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $group->uri_args));
        }
    }

    my $groups = $c->model('DBIC::Group')->root_groups;

    $c->stash(
        groups   => $groups,
        template => 'groups/edit.tt',
    );
}

=head2 list_action_groups

List groups that are valid for the action, request, and the specified
status via L<JSON>.

=cut

sub list_action_groups : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;

    my $status_id = $c->req->param('status_id');
    $status_id =~ s/\D//g;

    if ($status_id) {
        my $status = $c->model('DBIC::Status')->find($status_id);
        if ($status) {
            my $request = $c->stash->{request};

            my $groups = $request->groups_for_status($status);
            $c->stash(groups => [ map { $_->to_json } $groups->all ]);

            # Default to the parent group (for recycling)
            my $current_group = $request->current_action->groups->first;
            if (my $parent_group = $current_group->parent_group) {
                # Make sure the parent group is valid for the action
                if (my $selected_group = $groups->find($parent_group->id)) {
                    $c->stash(selected_group => $selected_group->to_json);
                }
            }

            if ($status->recycles_request and my $prev_action = $request->current_action->prev_action) {
                $c->stash(prev_group => $prev_action->group->to_json);
            }
        }
    }

    my $view = $c->view('JSON');
    $view->expose_stash([ qw/groups selected_group prev_group/ ]);
    $c->forward($view);
}

=head2 add_role

Add a role to the stashed group.

=cut

sub add_role : PathPart Chained('group') Args(0) {
    my ($self, $c) = @_;
    my $group = $c->stash->{group};

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $role  = $group->add_role($result->valid('name'));
            return $c->res->redirect($c->uri_for($self->action_for('view'), $group->uri_args));
        }
    }

    my $roles = $c->model('DBIC::Role')->search(undef, { order_by => 'name' });
    $c->stash(
        roles => $roles,
        template => 'groups/add_role.tt',
    );
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
