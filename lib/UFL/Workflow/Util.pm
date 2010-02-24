package UFL::Workflow::Util;

use strict;
use warnings;

=head1 NAME

UFL::Workflow::Util - Utility functions

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

General utility functions for L<UFL::Workflow>.

=head1 METHODS

=head2 escape_newlines

Replace newlines in the specified string with the HTML escape
character.  Useful for textareas.

=cut

sub escape_newlines {
    my ($string) = @_;

    $string =~ s/(?:\r\n|\r|\n)/&#010;/g;

    return $string;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
