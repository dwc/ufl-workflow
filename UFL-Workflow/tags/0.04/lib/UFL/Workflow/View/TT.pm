package UFL::Workflow::View::TT;

use strict;
use warnings;
use base qw/Catalyst::View::TT/;
use UFL::Workflow::Util;

__PACKAGE__->config(
    FILTERS => {
        escape_newlines => \&UFL::Workflow::Util::escape_newlines,
    }
);

=head1 NAME

UFL::Workflow::View::TT - TT view component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Template> view component.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
