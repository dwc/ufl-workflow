package UFL::Curriculum::Controller::Requests;

use strict;
use warnings;
use base qw/UFL::Curriculum::BaseController/;

=head1 NAME

UFL::Curriculum::Controller::Requests - Requests controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing requests.

=head1 METHODS

=head2 index

Display a list of the user's current requests.

=cut

sub index : Path Args(0) {
    my ($self, $c) = @_;

    my $requests = $c->user->requests;
    my $processes = $c->model('DBIC::Process')->search(undef, { order_by => 'name' });

    $c->stash(
        requests  => $requests,
        processes => $processes,
        template  => 'requests/index.tt',
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
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $request->uri_args ]));
        }
    }

    $c->stash(
        process  => $process,
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

    $c->stash(
        documents => $documents,
        template  => 'requests/view.tt',
    );
}

=head2 add_document

Add a document to the stashed request.

=cut

sub add_document : PathPart Chained('request') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success and my $upload = $c->req->upload('document')) {
            my $request = $c->stash->{request};

            my $filename = $upload->basename;
            my ($title, $extension) = ($filename =~ /(.+)\.([^.]+)$/);
            $extension = lc $extension;

            my @extensions = @{ $c->config->{documents}->{accepted_extensions} || [] };
            die 'File is not one of the allowed types'
                unless grep { /^\Q$extension\E$/i } @extensions;

            my $document;
            $request->result_source->schema->txn_do(sub {
                my %values = (
                    title     => $title,
                    extension => $extension,
                    contents  => $upload->slurp,
                );
                if (my $replaced_document_id = $result->valid('document_id')) {
                    $values{replaced_document_id} = $replaced_document_id;
                }

                $document = $request->add_document(\%values);

                my $destination = $c->path_to('root', $c->config->{documents}->{destination}, $document->uri_args);
                $destination->parent->mkpath;
                $upload->copy_to($destination)
                    or die 'Error copying document to destination directory';
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $request->uri_args ]));
        }
    }

    my $request   = $c->stash->{request};
    my $documents = $request->documents->search(
        { document_id => undef },
        { order_by    => 'insert_time' },
    );

    $c->stash(
        documents => $documents,
        template  => 'requests/add_document.tt'
    );
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
