package UFL::Workflow::Component::StandardColumns;

use strict;
use warnings;
use base qw/DBIx::Class/;

=head1 NAME

UFL::Workflow::Component::StandardColumns - Definition of columns used on most tables

=head1 SYNOPSIS

    # In your table class
    __PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns/);
    __PACKAGE__->add_standard_primary_key;
    __PACKAGE__->add_standard_columns;

=head1 DESCRIPTION

L<DBIx::Class> component for adding standard columns to table
definitions.

=head1 METHODS

=head2 add_standard_primary_key

Add the standard primary key column to the table definition: a column
named C<id>.

=cut

sub add_standard_primary_key {
    my ($class) = @_;

    $class->add_columns(
        id => {
            data_type         => 'integer',
            is_auto_increment => 1,
        },
    );
    $class->set_primary_key('id');
}

=head2 add_standard_columns

Add common columns to the table definition: C<insert_time> and
C<update_time>.

=cut

sub add_standard_columns {
    my ($class) = @_;

    $class->load_components(qw/InflateColumn::DateTime/);

    my %definition = (
        data_type     => 'timestamp',
        default_value => 'current timestamp',
    );
    $class->add_columns(
        insert_time => { %definition },
        update_time => { %definition },
    );
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
