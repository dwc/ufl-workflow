package UFL::Workflow::Controller::Requests;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

=head1 NAME

UFL::Workflow::Controller::Requests - Requests controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing requests.

=head1 METHODS

=head2 index

Redirect to the list of requests.

=cut

sub index : Path('') Args(0) {
    my ($self, $c) = @_;

    $c->res->redirect($c->uri_for($self->action_for('for_user')));
}

=head2 for_user

Display a list of the current requests for the current user.

=cut

sub for_user : Local Args(0) {
    my ($self, $c) = @_;

    my $user_requests = $c->user->requests->search(
        undef,
        { order_by => \q[update_time DESC, insert_time DESC] },
    );

    my $group_requests = $c->user->group_requests;

    my $processes = $c->model('DBIC::Process')->search(
        undef,
        { order_by => 'name' },
    );

    $c->stash(
        user_requests  => $user_requests,
        group_requests => $group_requests,
        processes      => $processes,
        template       => 'requests/for_user.tt',
    );
}

=head2 all

Display a list of the current requests entered by everyone.

=cut

sub all : Local Args(0) {
    my ($self, $c) = @_;

    my $requests = $c->model('DBIC::Request')->search(
        undef,
        { order_by => \q[update_time DESC, insert_time DESC] },
    );

    $c->stash(
        requests => $requests,
        template => 'requests/all.tt',
    );
}

=head2 add

Add a request that follows the specified process.

=cut

sub add : Local {
    my ($self, $c) = @_;

    my $process_id = $c->req->param('process_id');
    $process_id =~ s/\D//g;
    $c->detach('/default') unless $process_id;

    my $process = $c->model('DBIC::Process')->find($process_id);
    $c->detach('/default') unless $process;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $request = $process->add_request({
                user_id     => $c->user->obj->id,
                title       => $result->valid('title'),
                description => $result->valid('description'),
                group_id    => $result->valid('group_id'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
        }
    }

    my @groups = $process->first_step->role->groups;

    $c->stash(
        process  => $process,
        groups   => \@groups,
        template => 'requests/add.tt',
    );
}

=head2 request

Fetch the specified request.

=cut

sub request : PathPart('requests') Chained('/') CaptureArgs(1) {
    my ($self, $c, $request_id) = @_;

    my $request = $c->model('DBIC::Request')->find($request_id);
    $c->detach('/default') unless $request;

    $c->stash(request => $request);
}

=head2 view

Display basic information on the stashed request.

=cut

sub view : PathPart('') Chained('request') Args(0) {
    my ($self, $c) = @_;

    my $request   = $c->stash->{request};
    my $documents = $request->documents->search(undef, { order_by => 'insert_time' });
    my $statuses  = $c->model('DBIC::Status')->search(
        { is_initial => 0 },
        { order_by   => 'name' },
    );

    my @groups;
    if (my $next_step = $request->next_step) {
        @groups = $next_step->groups;
    }

    $c->stash(
        documents => $documents,
        statuses  => $statuses,
        groups    => @groups ? \@groups : undef,
        template  => 'requests/view.tt',
    );
}

=head2 add_document

Add a document to the stashed request.

=cut

sub add_document : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;

    my $request = $c->stash->{request};
    die 'Request is not open' unless $request->is_open;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success and my $upload = $c->req->upload('document')) {
            my $filename = $upload->basename;
            my ($title, $extension) = ($filename =~ /(.+)\.([^.]+)$/);
            $extension = lc $extension;

            my @extensions = @{ $c->config->{documents}->{accepted_extensions} || [] };
            die 'File is not one of the allowed types'
                unless grep { /^\Q$extension\E$/i } @extensions;

            my $destination = $c->path_to('root', $c->config->{documents}->{destination});
            my $document = $request->add_document({
                title                 => $title,
                extension             => $extension,
                replaced_document_id  => $result->valid('replaced_document_id') || undef,
                contents              => $upload->slurp,
                destination           => $destination,
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
        }
    }

    my $documents = $request->documents->search(
        { document_id => undef },
        { order_by    => 'insert_time' },
    );

    $c->stash(
        documents => $documents,
        template  => 'requests/add_document.tt'
    );
}

=head2 add_action

Add an action to this request, i.e., a decision by one of the users
with the role on the current step.

=cut

sub add_action : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;

    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $request = $c->stash->{request};
    die 'Request is not open' unless $request->is_open;

    my $result = $self->validate_form($c);
    $c->detach('view', $request->uri_args) unless $result->success;

    $request->result_source->schema->txn_do(sub {
        my $action = $request->actions->find($result->valid('action_id'));
        my $status = $c->model('DBIC::Status')->find($result->valid('status_id'));
        $c->detach('/default') unless $action and $status;

        my $group;
        if (my $group_id = $result->valid('group_id')) {
            $group = $c->model('DBIC::Group')->find($group_id);
            $c->detach('/default') unless $group;
        }

        $action->update_status({
            status  => $status,
            actor   => $c->user->obj,
            group   => $group,
            comment => $result->valid('comment'),
        });
    });

    return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
