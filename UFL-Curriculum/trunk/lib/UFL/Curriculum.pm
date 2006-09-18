package UFL::Curriculum;

use strict;
use warnings;
use Catalyst qw/
    ConfigLoader
    Static::Simple
/;

our $VERSION = '0.01_01';

__PACKAGE__->setup;

=head1 NAME

UFL::Curriculum - Curriculum tracking for the University of Florida

=head1 SYNOPSIS

    script/ufl_curriculum_server.pl

=head1 DESCRIPTION

Each semester, professors identify new or modified undergraduate and
graduate courses for the student body.  The professors create course
requests and submit them for approval.  This application tracks these
requests.

=head1 SEE ALSO

=over 4

=item * L<UFL::Curriculum::Controller::Root>

=item * L<Catalyst>

=back

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
