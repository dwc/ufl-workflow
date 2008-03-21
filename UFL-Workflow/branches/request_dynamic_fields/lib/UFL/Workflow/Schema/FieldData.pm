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

=head2 next_field

Return the next L<UFL::Workflow::Schema::Field> associated with
this request.

=cut

sub next_field_data {
    my ($self) = @_;
    my $field_data;
    my $next_field = $self->field->next_field;
    if ( $next_field ) {
        $field_data = $self->result_source->schema->resultset('FieldData')->search({ 
            field_id   => $next_field->id,
	    request_id => $self->request_id,
        })->first;
        return $field_data;
    }
}
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
