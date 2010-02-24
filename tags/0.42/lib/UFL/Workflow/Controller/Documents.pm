package UFL::Workflow::Controller::Documents;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;
use File::stat;

__PACKAGE__->mk_accessors(qw/destination/);

=head1 NAME

UFL::Workflow::Controller::Documents - Documents controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing documents.

=head1 METHODS

=head2 document

Fetch the specified document.

=cut

sub document : PathPart('documents') Chained('/') CaptureArgs(1) {
    my ($self, $c, $document_id) = @_;

    my $document = $c->model('DBIC::Document')->find($document_id);
    $c->detach('/default') unless $document;
    $c->detach('/forbidden') unless $c->user->can_view($document->request);

    $c->stash(document => $document);
}

=head2 download

Send the stashed document to the user.

=cut

sub download : PathPart Chained('document') Args(0) {
    my ($self, $c) = @_;

    my $document = $c->stash->{document};

    my $path = Path::Class::Dir->new($self->destination, $document->path);
    $c->detach('/default') unless -r $path;

    my $stat = stat $path;

    $c->res->headers->content_type($document->type);
    $c->res->headers->content_length($stat->size);
    $c->res->headers->last_modified($stat->mtime);

    my $filename = $document->name . '.' . $document->extension;
    $c->res->header('Content-Disposition', qq[attachment; filename="$filename"]);

    my $fh = IO::File->new($path, 'r') or die "Error opening $path";
    binmode $fh;
    $c->res->body($fh);
}

=head2 manage

Ensure that the current user can manage the request associated with
the specified document.

=cut

sub manage : Chained('document') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $document = $c->stash->{document};
    $c->detach('/forbidden') unless $c->user->can_manage($document->request);
}

=head2 remove

Remove the stashed document from the request. The document isn't
actually removed; we just set a flag to hide it.

=cut

sub remove : PathPart Chained('manage') Args(0) {
    my ($self, $c) = @_;
    
    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $document = $c->stash->{document};
    my $request = $document->request;

    $c->model('DBIC')->schema->txn_do(sub {
        $document->remove;
        $self->send_changed_document_email($c, $request, $c->user->obj, $document, $document, undef);
    });

    return $c->res->redirect($c->uri_for($c->controller('Requests')->action_for('view'), $request->uri_args));
}

=head2 recover

Recover the document for this request.

=cut

sub recover : PathPart Chained('manage') Args(0) {
    my ($self, $c) = @_;
    
    die 'Method must be POST' unless $c->req->method eq 'POST';

    my $document = $c->stash->{document};
    my $request = $document->request;

    $c->model('DBIC')->schema->txn_do(sub {
        $document->recover;
        $self->send_changed_document_email($c, $request, $c->user->obj, $document, undef, $document);
    });

    return $c->res->redirect($c->uri_for($c->controller('Requests')->action_for('view'), $request->uri_args));
}

=head2 send_changed_document_email

Send notification that a document was changed for a
L<UFL::Workflow::Schema::Request>.

=cut

sub send_changed_document_email {
    my ($self, $c, $request, $actor, $document, $removed_document, $recovered_document) = @_;

    my $possible_actors = $request->possible_actors;
    my $past_actors = $request->past_actors;

    my @to_addresses;
    push @to_addresses, map { $_->email } grep { $_->wants_email } $possible_actors->all;
    push @to_addresses, map { $_->email } grep { $_->wants_email } $past_actors->all;

    $c->stash(
        request            => $request,
        actor              => $actor,
        document           => $document,
        removed_document   => $removed_document,
        recovered_document => $recovered_document,
        email              => {
            from     => $c->config->{email}->{from_address},
            to       => join(', ', @to_addresses),
            subject  => $request->subject('New document added to '),
            header   => [
                'Return-Path' => $c->config->{email}->{admin_address},
                'Reply-To'    => $actor->email,
                Cc            => $request->submitter->email,
                'In-Reply-To' => '<' . $request->message_id($c->req->uri->host_port) . '>',
            ],
            template => 'text_plain/changed_document.tt',
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
