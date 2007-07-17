package UFL::Workflow::Controller::Documents;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;
use File::stat;

__PACKAGE__->mk_accessors(qw/destination accepted_extensions/);

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

    $c->stash(document => $document);
}

=head2 download

Send the stashed document to the user.

=cut

sub download : PathPart('download') Chained('document') Args(0) {
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

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
