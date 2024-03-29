package UFL::Workflow::Controller::Requests;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController::Uploads/;

=head1 NAME

UFL::Workflow::Controller::Requests - Requests controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing requests.

=head1 METHODS

=head2 for_user

Display a list of the current requests for the current user.

=cut

sub for_user : Local Args(0) {
    my ($self, $c) = @_;

    my $user_requests  = $c->user->requests;

    $c->stash(
        user_requests => $user_requests,
        template      => 'requests/for_user.tt',
    );
}

=head2 by_group

Display a list of the current requests based on the groups of the
current user.

=cut

sub by_group : Local Args(0) {
    my ($self, $c) = @_;

    my $group_requests = $c->user->group_requests;

    $c->stash(
        group_requests => $group_requests,
        template       => 'requests/by_group.tt',
    );
}

=head2 pending_decision

Display a list of requests pending action by the current user.

=cut

sub pending_decision : Local Args(0) {
    my ($self, $c) = @_;

    my $actions = $c->user->pending_actions;

    $c->stash(
        actions  => $actions,
        template => 'requests/pending_decision.tt',
    );
}

=head2 reports

Show a list of requests matching the specified criteria.

=cut

sub reports : Local Args(0) {
    my ($self, $c) = @_;

    my $result = $self->validate_form($c);

    my $page = $result->valid('page') || 1;

    # Default to all requests
    my $requests = $c->model('DBIC::Request')->search(
        {},
        {
            join     => [ qw/submitter process documents/, { actions => [ qw/actor action_groups/ ] } ],
            order_by => \q[me.update_time DESC, me.insert_time DESC],
            distinct => 1,
            page     => $page,
            rows     => 10,
        },
    );

    if (my $query = $result->valid('query')) {
        my @fields = qw/
            me.title
            me.description
            submitter.username
            actor.username
            actions.comment
            documents.name
        /;

        my $query_field = $result->valid('query_field');
        my @selected_fields = $query_field == 0 ? @fields : $fields[$query_field - 1];

        my @words = split / /, lc $query;
        my @queries;
        foreach my $field (@selected_fields) {
 	     foreach my $word (@words) {
                push @queries, { "LOWER($field)" => { 'like', '%' . $word . '%' } };
	     }
        }

        $requests = $requests->search({ -or => [ @queries ] });
    }

    # Constrain requests based on the selected processes
    if (my $process_ids = $result->valid('process_id')) {
        $requests = $requests->search({ 'me.process_id' => { -in => $process_ids } });
    }

    # Constrain requests based on the selected groups
    if (my $group_ids = $result->valid('group_id')) {
        $requests = $requests->search({ 'action_groups.group_id' => { -in => $group_ids } });
    }

    # Constrain requests based on the selected statuses
    if (my $status_ids = $result->valid('status_id')) {
        $requests = $requests->search({ 'actions.status_id' => { -in => $status_ids } });
    }

    # Constrain requests based on a date range
    # XXX: Remove formatter junk when DBIx::Class gets support for objects
    my $formatter = $c->model('DBIC')->schema->storage->datetime_parser_type;
    eval "require $formatter"; die $@ if $@;
    if (my $start_date = $result->valid('start_date')) {
        $start_date->set_formatter($formatter);
        $requests = $requests->search({ 'me.update_time' => { '>=' => $start_date } });
    }

    if (my $end_date = $result->valid('end_date')) {
        $end_date->set_formatter($formatter);
        $end_date->add(days => 1);
        $requests = $requests->search({ 'me.update_time' => { '<' => $end_date } });
    }

    my $processes = $c->model('DBIC::Process')->search(undef, { order_by => 'name' });
    $processes = $processes->search({ 'me.enabled' => 1 })
        unless $result->valid('inactive_processes');

    my $groups    = $c->model('DBIC::Group')->search(undef, { order_by => 'name' });
    my $statuses  = $c->model('DBIC::Status')->search(undef, { order_by => 'name' });

    $c->stash(
        end_date   => DateTime->now,
        past_day   => DateTime->now->subtract(days => 1),
        past_week  => DateTime->now->subtract(weeks => 1),
        past_month => DateTime->now->subtract(months => 1),
        past_year  => DateTime->now->subtract(years => 1),
        requests   => $requests,
        processes  => $processes,
        groups     => $groups,
        statuses   => $statuses,
        template   => 'requests/reports.tt',
    );
}

=head2 request

Fetch the specified request.

=cut

sub request : PathPart('requests') Chained('/') CaptureArgs(1) {
    my ($self, $c, $request_id) = @_;

    my $request = $c->model('DBIC::Request')->find($request_id);
    $c->detach('/default') unless $request;
    $c->detach('/forbidden') unless $c->user->can_view($request) or
        $c->check_any_user_role('Administrator', 'Help Desk');

    $c->stash(request => $request);
}

=head2 version

Fetch the specified version.

=cut

sub version : PathPart('versions') Chained('request') CaptureArgs(1) {
    my ($self, $c, $num) = @_;

    my $request = $c->stash->{request};
    my $version = $request->versions->find({ num => $num });
    $c->detach('/default') unless $version;

    $c->stash(version => $version);
}

=head2 view

Display basic information on the stashed request.

=cut

sub view : PathPart('') Chained('request') Args(0) {
    my ($self, $c) = @_;

    my $request = $c->stash->{request};

    my $versions = $request->versions->search({}, { order_by => 'num' });

    my $documents = $request->active_documents;
    my $removed_documents = $request->removed_documents;
    my $replaced_documents = $request->replaced_documents;

    $c->stash(
        versions           => $versions,
        documents          => $documents,
        removed_documents  => $removed_documents,
        replaced_documents => $replaced_documents,
        template           => 'requests/view.tt',
    );
}

=head2 view_version

Display basic information about the stashed version.

=cut

sub view_version : PathPart('') Chained('version') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'requests/version.tt');
}

=head2 manage

Ensure that the current user can manage the stashed request.

=cut

sub manage : Chained('request') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $request = $c->stash->{request};
    $c->detach('/forbidden') unless $c->user->can_manage($request);
}

=head2 edit

Edit the stashed request.

=cut

sub edit : PathPart Chained('manage') Args(0) {
    my ($self, $c) = @_;

    my $request = $c->stash->{request};

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $previous_title = $request->title;
            my $previous_description = $request->description;

            $c->model('DBIC')->schema->txn_do(sub {
                my $version = $request->add_version($c->user->obj);

                $request->update({
                    title       => $result->valid('title'),
                    description => $result->valid('description'),
                });

                $self->send_changed_request_email($c, $request, $c->user->obj, '', $previous_title, $previous_description);
            });
        }

        return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
    }

    $c->stash(template => 'requests/edit.tt');
}

=head2 add_document

Add a document to the stashed request.

=cut

sub add_document : PathPart Chained('manage') Args(0) {
    my ($self, $c) = @_;

    my $request = $c->stash->{request};

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success and my $upload = $c->req->upload('document')) {
            my $replaced_document_id = $result->valid('replaced_document_id');

            $c->model('DBIC')->schema->txn_do(sub {            
                my $document = $request->add_document(
                    $c->user->obj,
                    $upload->basename,
                    $upload->slurp,
                    $c->controller('Documents')->destination,
                    $replaced_document_id,
                );

                my $replaced_document;
                if ($replaced_document_id) {
                    $replaced_document = $request->documents->find($replaced_document_id);
                }

                $self->send_new_document_email($c, $request, $c->user->obj, $document, $replaced_document);
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
        }
    }

    my $documents = $request->active_documents;

    $c->stash(
        documents => $documents,
        template  => 'requests/add_document.tt',
    );
}

=head2 decide_on

Ensure that the current user can decide on the stashed request.

=cut

sub decide_on : Chained('request') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $request = $c->stash->{request};
    $c->detach('/forbidden') unless $c->user->can_decide_on($request->current_action);
}

=head2 update_status

Add an action to this request, i.e., a decision by one of the users
with the role on the current step.

=cut

sub update_status : PathPart Chained('decide_on') Args(0) {
    my ($self, $c) = @_;

    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $request = $c->stash->{request};

    my $result = $self->validate_form($c);
    $c->detach('view', $request->uri_args) unless $result->success;

    my $status = $c->model('DBIC::Status')->find($result->valid('status_id'));
    $c->detach('/default') unless $status;

    my $group;
    if (my $group_id = $result->valid('group_id')) {
        $group = $c->model('DBIC::Group')->find($group_id);
        $c->detach('/default') unless $group;
    }

    $c->model('DBIC')->schema->txn_do(sub {
        my $comment = $result->valid('comment');
        $request->update_status($status, $c->user->obj, $group, $comment);

        $self->send_changed_request_email($c, $request, $c->user->obj, $comment);
        if ($request->is_open) {
            $self->send_new_action_email($c, $request, $c->user->obj, $comment);
        }
    });

    return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
}

=head2 list_action_groups

List groups that are valid for the action, request, and the specified
status via L<JSON>.

=cut

sub list_action_groups : PathPart Chained('decide_on') Args(0) {
    my ($self, $c) = @_;

    my $status_id = $c->req->param('status_id');
    $status_id =~ s/\D//g;

    if ($status_id) {
        my $status = $c->model('DBIC::Status')->find($status_id);
        if ($status) {
            my $request = $c->stash->{request};

            my $groups = $request->groups_for_status($status);
            $c->stash(groups => [ map { $_->to_json } $groups->all ]);

            if (my $selected_group = $request->default_group_for_status($status)) {
                $c->stash(selected_group => $selected_group->to_json);
            }
        }
    }

    my $view = $c->view('JSON');
    $view->expose_stash([ qw/groups selected_group/ ]);
    $c->forward($view);
}

=head2 list_processes

List processes via L<JSON>, including whether they are currently
enabled, for the reporting screen.

=cut

sub list_processes : Local Args(0) {
    my ($self, $c) = @_;

    my @process_ids = map { int } $c->req->param('process_id');
    if (@process_ids) {
        my @processes = $c->model('DBIC::Process')->search({ id => { -in => [ @process_ids ] }});

        my %selected_processes;
        foreach my $process (@processes) {
            $selected_processes{$process->id} = $process->to_json;
        }

        $c->stash(selected_processes => \%selected_processes);
    }

    my @processes = $c->model('DBIC::Process')->search(undef, { order_by => 'name' });
    $c->stash(processes => [ map { $_->to_json } @processes ]);

    my $view = $c->view('JSON');
    $view->expose_stash([ qw/processes selected_processes/ ]);
    $c->forward($view);
}

=head2 send_changed_request_email

Send notification that a L<UFL::Workflow::Schema::Request> has changed
to the submitter and to users who have previously acted on it.

=cut

sub send_changed_request_email {
    my ($self, $c, $request, $actor, $comment, $previous_title, $previous_description) = @_;

    my $past_actors  = $request->past_actors;
    my @to_addresses = map { $_->email } grep { $_->wants_email } $past_actors->all;

    # Get latest request information
    $request->discard_changes;

    $c->stash(
        request => $request,
        actor   => $actor,
        comment => $comment,
        previous_title => $previous_title,
        previous_description => $previous_description,
        email => {
            from     => $c->config->{email}->{from_address},
            to       => join(', ', @to_addresses),
            subject  => $request->subject('Change to '),
            header   => [
                'Return-Path' => $c->config->{email}->{admin_address},
                'Reply-To'    => $actor->email,
                Cc            => $request->submitter->email,
                'In-Reply-To' => '<' . $request->message_id($c->req->uri->host_port) . '>',
            ],
            template => 'text_plain/changed_request.tt',
        },
    );

    $self->send_email($c);
}

=head2 send_new_action_email

Send notification that a L<UFL::Workflow::Schema::Request> must be
acted upon to those users who can act on it based on their
L<UFL::Workflow::Schema::Group>s and L<UFL::Workflow::Schema::Role>s.

=cut

sub send_new_action_email {
    my ($self, $c, $request, $actor, $comment) = @_;

    my $possible_actors = $request->possible_actors;
    my @to_addresses    = map { $_->email } grep { $_->wants_email } $possible_actors->all;

    # Get latest request information
    $request->discard_changes;

    $c->stash(
        request => $request,
        actor   => $actor,
        comment => $comment,
        email   => {
            from     => $c->config->{email}->{from_address},
            to       => join(', ', @to_addresses),
            subject  => $request->subject('Decision needed on '),
            header   => [
                'Return-Path' => $c->config->{email}->{admin_address},
                'Reply-To'    => $actor->email,
                'In-Reply-To' => '<' . $request->message_id($c->req->uri->host_port) . '>',
            ],
            template => 'text_plain/new_action.tt',
        },
    );

    $self->send_email($c);
}

=head2 send_new_document_email

Send notification that a new document was uploaded for a
L<UFL::Workflow::Schema::Request>.

=cut

sub send_new_document_email {
    my ($self, $c, $request, $actor, $document, $replaced_document) = @_;

    my $possible_actors = $request->possible_actors;
    my $past_actors = $request->past_actors;

    my @to_addresses;
    push @to_addresses, map { $_->email } grep { $_->wants_email } $possible_actors->all;
    push @to_addresses, map { $_->email } grep { $_->wants_email } $past_actors->all;

    # Get latest request information
    $request->discard_changes;

    $c->stash(
        request           => $request,
        actor             => $actor,
        document          => $document,
        replaced_document => $replaced_document,
        email             => {
            from     => $c->config->{email}->{from_address},
            to       => join(', ', @to_addresses),
            subject  => $request->subject('New document added to '),
            header   => [
                'Return-Path' => $c->config->{email}->{admin_address},
                'Reply-To'    => $actor->email,
                Cc            => $request->submitter->email,
                'In-Reply-To' => '<' . $request->message_id($c->req->uri->host_port) . '>',
            ],
            template => 'text_plain/new_document.tt',
        },
    );

    $self->send_email($c);
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
