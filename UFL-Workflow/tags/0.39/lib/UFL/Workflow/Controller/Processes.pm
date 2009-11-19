package UFL::Workflow::Controller::Processes;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController::Uploads/;

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
            my $process = $c->user->processes->create({
                name         => $result->valid('name'),
                description  => $result->valid('description'),
                def_req_desc => $result->valid('def_req_desc'),
                enabled      => $result->valid('enabled') ? 1 : 0,
                restricted   => $result->valid('restricted') ? 1 : 0,
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
                name         => $result->valid('name'),
                description  => $result->valid('description'),
                def_req_desc => $result->valid('def_req_desc'),
                enabled      => $result->valid('enabled') ? 1 : 0,
                restricted   => $result->valid('restricted') ? 1 : 0,
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

=head2 add_request

Add a request that follows the specified process.

=cut

sub add_request : PathPart Chained('process') Args(0) {
    my ($self, $c) = @_;

    my $process = $c->stash->{process};
    die 'Process is not enabled' unless $process->enabled;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $group = $c->model('DBIC::Group')->find($result->valid('group_id'));
            $c->detach('/default') unless $group;

            # Use a transaction so e.g. if the document is bad the request isn't added
            my $request;
            $c->model('DBIC')->schema->txn_do(sub {
                $request = $process->add_request(
                    $result->valid('title'),
                    $result->valid('description'),
                    $c->user->obj,
                    $group,
                );

                # Make sure we get insert_time and update_time
                $request->discard_changes;

                if (my $upload = $c->req->upload('document')) {
                    my $document = $request->add_document(
                        $c->user->obj,
                        $upload->basename,
                        $upload->slurp,
                        $c->controller('Documents')->destination,
                    );
                }

                $self->send_new_request_email($c, $request);
            });

            return $c->res->redirect($c->uri_for($c->controller('Requests')->action_for('view'), $request->uri_args));
        }
    }

    my $groups;
    if (my $first_step = $process->first_step) {
        $groups = $first_step->role->groups->search(undef, { order_by => 'name' });
    }

    $c->stash(
        process  => $process,
        groups   => $groups,
        template => 'processes/add_request.tt',
    );
}

=head2 requests

List requests for the stashed L<UFL::Workflow::Schema::Process>.

=cut

sub requests : PathPart Chained('process') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'processes/requests.tt');
}

=head2 send_new_request_email

Send notification that a new L<UFL::Workflow::Schema::Request> has
been entered to those who can act on it.

=cut

sub send_new_request_email {
    my ($self, $c, $request) = @_;

    my $submitter = $request->submitter;

    my $possible_actors = $request->possible_actors;
    my @to_addresses    = map { $_->email } grep { $_->wants_email } $possible_actors->all;

    $c->stash(
        request => $request,
        email => {
            from     => $c->config->{email}->{from_address},
            to       => join(', ', @to_addresses),
            subject  => $request->subject('New: '),
            header   => [
                'Return-Path' => $c->config->{email}->{admin_address},
                'Reply-To'    => $submitter->email,
                Cc            => $submitter->email,
                'Message-Id'  => '<' . $request->message_id($c->req->uri->host_port) . '>',
            ],
            template => 'text_plain/new_request.tt',
        },
    );

    $c->forward($c->view('Email'));
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
