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

=head2 for_user

Display a list of the current requests for the current user.

=cut

sub for_user : Local Args(0) {
    my ($self, $c) = @_;

    my $user_requests  = $c->user->requests;
    my $group_requests = $c->user->group_requests;

    $c->stash(
        user_requests  => $user_requests,
        group_requests => $group_requests,
        template       => 'requests/for_user.tt',
    );
}

=head2 reports

Show a list of requests matching the specified criteria.

=cut

sub reports : Local Args(0) {
    my ($self, $c) = @_;

    my $result = $self->validate_form($c);
    if ($result->success and my $group_id = $result->valid('group_id')) {
        my $group = $c->model('DBIC::Group')->find($group_id);
        $c->stash(group => $group);
    }

    my $groups = $c->model('DBIC::Group')->root_groups;

    $c->stash(
        groups    => $groups,
        template  => 'requests/reports.tt',
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

    my @groups;
    if (my $next_step = $request->next_step) {
        @groups = $next_step->groups;
    }

    $c->stash(
        documents => $documents,
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
    die 'User cannot manage request' unless $c->user->can_manage($request);

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success and my $upload = $c->req->upload('document')) {
            my $filename   = $upload->basename;
            my @extensions = @{ $c->config->{documents}->{accepted_extensions} || [] };
            die 'File is not one of the allowed types'
                unless grep { $filename =~ /\.\Q$_\E$/i } @extensions;

            my $replaced_document;
            if (my $replaced_document_id = $result->valid('replaced_document_id')) {
                $replaced_document = $request->documents->find($replaced_document_id);
                $c->detach('/default') unless $replaced_document;
            }

            my $document = $request->add_document(
                $c->user->obj,
                $filename,
                $upload->slurp,
                $c->config->{documents}->{destination},
                $replaced_document,
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
        template  => 'requests/add_document.tt'
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

    my $comment = $result->valid('comment');
    $request->update_status($status, $c->user->obj, $group, $comment);

    return $c->res->redirect($c->uri_for($self->action_for('view'), $request->uri_args));
}

=head2 list_groups

List groups that are valid for the request and the specified status
via L<JSON>.

=cut

sub list_groups : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;

    my $status_id = $c->req->param('status_id');
    $status_id =~ s/\D//g;

    if ($status_id) {
        my $status = $c->model('DBIC::Status')->find($status_id);
        if ($status) {
            my $request = $c->stash->{request};

            my @groups = $request->groups_for_status($status);
            $c->stash(groups => [ map { $_->to_json } @groups ]);
        }
    }

    my $view = $c->view('JSON');
    $view->expose_stash([ qw/groups/ ]);
    $c->forward($view);
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
