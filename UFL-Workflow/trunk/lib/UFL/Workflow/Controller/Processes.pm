package UFL::Workflow::Controller::Processes;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

=head1 NAME

UFL::Workflow::Controller::Processes - Processes controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing processes.

=head1 METHODS

=head2 index 

Display a list of current processes.

=cut

sub index : Path('') Args(0) {
    my ($self, $c) = @_;

    my $processes = $c->model('DBIC::Process')->search(undef, { order_by => 'name' });

    $c->stash(
        processes => $processes,
        template  => 'processes/index.tt',
    );
}

=head2 add

Add a new process.

=cut

sub add : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $process = $c->user->processes->find_or_create({
                name        => $result->valid('name'),
                description => $result->valid('description'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $process->uri_args));
        }
    }

    $c->stash(template => 'processes/add.tt');
}

=head2 process

Fetch the specified process.

=cut

sub process : PathPart('processes') Chained('/') CaptureArgs(1) {
    my ($self, $c, $process_id) = @_;

    my $process = $c->model('DBIC::Process')->find($process_id);
    $c->detach('/default') unless $process;

    $c->stash(process => $process);
}

=head2 view

Display basic information on the stashed process.

=cut

sub view : PathPart('') Chained('process') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'processes/view.tt');
}

=head2 edit

Edit the stashed process.

=cut

sub edit : PathPart Chained('process') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $process = $c->stash->{process};
            $process->update({
                name        => $result->valid('name'),
                description => $result->valid('description'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $process->uri_args));
        }
    }

    $c->stash(template => 'processes/edit.tt');
}

=head2 add_step

Add a step to the stashed process.

=cut

sub add_step : PathPart Chained('process') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $process = $c->stash->{process};

            my $role = $c->model('DBIC::Role')->find($result->valid('role_id'));
            $c->detach('/default') unless $role;

            my $step = $process->add_step($result->valid('name'), $role);

            return $c->res->redirect($c->uri_for($self->action_for('view'), $process->uri_args));
        }
    }

    my $roles = $c->model('DBIC::Role')->search(undef, {
        order_by => 'name'
    });

    $c->stash(
        roles    => $roles,
        template => 'processes/add_step.tt',
    );
}

=head2 delete_step

Remove the specified step from the stashed process.

=cut

sub delete_step : PathPart Chained('process') Args(0) {
    my ($self, $c) = @_;

    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $process = $c->stash->{process};

    my $result = $self->validate_form($c);
    if ($result->success) {
        my $step = $process->steps->find($result->valid('step_id'));
        $c->detach('/default') unless $step;

        $step->delete;
    }

    return $c->res->redirect($c->uri_for($self->action_for('view'), $process->uri_args));
}

=head2 move_step_up

Move the specified step up one position in the stashed process.

=cut

sub move_step_up : PathPart Chained('process') Args(0) {
    my ($self, $c) = @_;

    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $process = $c->stash->{process};

    my $result = $self->validate_form($c);
    if ($result->success) {
        my $step = $process->steps->find($result->valid('step_id'));
        $c->detach('/default') unless $step;

        $step->move_up;
    }

    return $c->res->redirect($c->uri_for($self->action_for('view'), $process->uri_args));
}

=head2 move_step_down

Move the specified step down one position in the stashed process.

=cut

sub move_step_down : PathPart Chained('process') Args(0) {
    my ($self, $c) = @_;

    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $process = $c->stash->{process};

    my $result = $self->validate_form($c);
    if ($result->success) {
        my $step = $process->steps->find($result->valid('step_id'));
        $c->detach('/default') unless $step;

        $step->move_down;
    }

    return $c->res->redirect($c->uri_for($self->action_for('view'), $process->uri_args));
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
