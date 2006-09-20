package UFL::Curriculum::Schema;

use strict;
use warnings;
use base qw/DBIx::Class::Schema/;
use Module::Find ();

__PACKAGE__->load_classes(map {
    substr $_, length __PACKAGE__ . '::'
} Module::Find::findallmod(__PACKAGE__ . '::ResultSource'));

=head1 NAME

UFL::Curriculum::Schema - Database schema for UFL::Curriculum

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<DBIx::Class::Schema> for L<UFL::Curriculum>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.edu<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
