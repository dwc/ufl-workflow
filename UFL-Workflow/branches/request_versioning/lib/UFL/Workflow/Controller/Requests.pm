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
        undef,
        {
            join     => { actions => [ qw/actor action_groups/ ] },
            prefetch => [ qw/submitter process documents/ ],
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
    my $formatter = $c->model('DBIC')->storage->datetime_parser_type;
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

    $c->stash(request => $request);
}

=head2 view

Display basic information on the stashed request.

=cut

sub view : PathPart('') Chained('request') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'requests/view.tt');
}

=head2 add_document

Add a document to the stashed request.

=cut

sub add_document : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;

    my $request = $c->stash->{request};
    die 'User cannot manage request' unless $c->user->can_manage($request);

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success and my $upload = $c->req->upload('document')) {
            my $document = $request->add_document(
                $c->user->obj,
                $upload->basename,
                $upload->slurp,
                $c->controller('Documents')->destination,
                $result->valid('replaced_document_id'),
            );

            return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
        }
    }

    my $documents = $request->documents->search(
        { document_id => undef },
        { order_by    => 'insert_time' },
    );

    $c->stash(
        documents => $documents,
        template  => 'requests/add_document.tt',
    );
}

=head2 update_status

Add an action to this request, i.e., a decision by one of the users
with the role on the current step.

=cut

sub update_status : PathPart Chained('request') Args(0) {
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

        # Make sure we get update_time
        $request->discard_changes;

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

sub list_action_groups : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;

    my $status_id = $c->req->param('status_id');
    $status_id =~ s/\D//g;

    if ($status_id) {
        my $status = $c->model('DBIC::Status')->find($status_id);
        if ($status) {
            my $request = $c->stash->{request};

            my @groups = $request->groups_for_status($status);
            $c->stash(groups => [ map { $_->to_json } @groups ]);

            my $current_group = $request->current_action->groups->first;
            if (my $parent_group = $current_group->parent_group) {
                # Default to the parent group
                foreach my $group (@groups) {
                    if ($group->id == $parent_group->id) {
                        $c->stash(selected_group => $group->to_json);
                        last;
                    }
                }
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
=head2 edit_field

edits field and creats a version

=cut

sub edit : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;
    my $request = $c->stash->{request};
    die 'User cannot manage request' unless $c->user->can_manage($request);

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
	my $result_field = $request->validate_fields($c);
	if ( $result->success and $result_field->success ) {

            # save to DB how wait for some more time.
            $request->update({
                title       => $result->valid('title'),
                description => $result->valid('description'),
            });
	    $request->update_field_data($result_field);
            return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
         }
    }

    $c->stash(
        request   => $request,
        template  => 'requests/edit.tt',
    );
}

=head2 get_valid_field_id

returns the valid field else none.

=cut
sub get_valid_field_id{
    my ($self, $c, @params) = @_;

    my $request = $c->stash->{request};
    foreach my $para ( @params ) {
        my $field = $request->first_field_data();
	while ($field){
            if ( lc($field->field_id) eq lc($para)){
	        return $para;
            }
	    $field = $field->next_field_data;
        }
    }
}

=head2 edit_field

edits a single field and creats a version

=cut

sub edit_field : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;
    
    my $answer = "Failed!";
    my $new_data;
    # get the field id
    if ( my $field_id = $self->get_valid_field_id($c, $c->request->param) ) {
        my $request = $c->stash->{request};
        my $result = $request->validate_field($c, $field_id);
        #validate the field content.
        $new_data = $request->get_field_data_by_id($field_id)->value;
        if ($result->success) {
            ## perform save operation to DB.
            if ( $new_data = $result->valid($field_id)) {
                $request->get_field_data_by_id($field_id)->update({
                    value => $new_data,
                });	
                $answer = "Saved!";
            }
        }
        else {
            $answer = $c->stash->{field_errors}[0];
        }
    }
    $c->stash({
        answer =>  $answer,
	value  =>  $new_data,
    });

    my $view = $c->view('JSON');
    $view->expose_stash([ qw/answer value/]);
    $c->forward($view);
}

=head2 send_changed_request_email

Send notification that a L<UFL::Workflow::Schema::Request> has changed
to the submitter and to users who have previously acted on it.

=cut

sub send_changed_request_email {
    my ($self, $c, $request, $actor, $comment) = @_;

    my $past_actors  = $request->past_actors;
    my @to_addresses = map { $_->email } grep { $_->wants_email } $past_actors->all;

    $c->stash(
        request => $request,
        actor   => $actor,
        comment => $comment,
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

    $c->forward($c->view('Email'));
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

    $c->forward($c->view('Email'));
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
