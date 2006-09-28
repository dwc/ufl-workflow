package UFL::Curriculum::Controller::Processes;

use strict;
use warnings;
use base qw/UFL::Curriculum::BaseController/;

=head1 NAME

UFL::Curriculum::Controller::Processes - Processes controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing processes.

=head1 METHODS

=head2 index 

Display a list of current processes.

=cut

sub index : Path Args(0) {
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
                name => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $process->uri_args ]));
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

            my $values = $result->valid;
            foreach my $key (keys %$values) {
                $process->$key($values->{$key}) if $process->can($key);
            }

            # TODO: Unique check
            $process->update;

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $process->uri_args ]));
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

            my $step = $process->add_step({
                role_id => $result->valid('role_id'),
                name    => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $process->uri_args ]));
        }
    }

    my $roles = $c->model('DBIC::Role')->search(undef, {
        join     => 'group',
        order_by => 'group.name, me.name'
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

    return $c->res->redirect($c->uri_for($self->action_for('view'), [ $process->uri_args ]));
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
