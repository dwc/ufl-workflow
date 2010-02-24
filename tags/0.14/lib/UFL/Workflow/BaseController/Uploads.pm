package UFL::Workflow::BaseController::Uploads;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

__PACKAGE__->mk_accessors(qw/accepted_extensions/);

=head1 NAME

UFL::Workflow::BaseController::Uploads - Base upload-handling controller

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Base L<Catalyst> controller component for verifying uploads.

=head1 METHODS

=head2 validate_form

Validate any form uploads and stash the results.

=cut

sub validate_form {
    my $self = shift;

    my ($c) = @_;

    my $result = $self->SUPER::validate_form(@_);

    my @fields = $c->req->upload;
    foreach my $field (@fields) {
        $result->set_invalid($field => 'EXTENSION')
            unless $self->is_valid_upload($c->req->upload($field));
    }

    # Restash form errors
    $c->stash(form_errors => $result->messages($c->action->name));

    return $result;
}

=head2 is_valid_upload

Return true if the specified L<Catalyst::Request::Upload> contains a
file with one of the accepted extensions.

=cut

sub is_valid_upload {
    my ($self, $upload) = @_;

    my @extensions = @{ $self->accepted_extensions || [] };
    my $filename   = $upload->basename;

    return grep { $filename =~ /\.\Q$_\E$/i } @extensions;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
