package UFL::Workflow::Schema::FieldData;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Scalar::Util qw/blessed/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('field_data');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    request_id => {
        data_type => 'integer',
    },
    field_id => {
        data_type => 'integer',
    },
    value => {
        data_type   => 'varchar',
        size        => 8192,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    request => 'UFL::Workflow::Schema::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    field => 'UFL::Workflow::Schema::Field',
    'field_id',
);

__PACKAGE__->resultset_class('UFL::Workflow::ResultSet::FieldData');

=head1 NAME

UFL::Workflow::Schema::Action - Action table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Action table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 uri_args

Return the list of URI path arguments needed to identify this action.

=cut

sub uri_args {
    my ($self) = @_;

    return [ $self->id ];
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
