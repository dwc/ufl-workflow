package UFL::Workflow::Schema::Status;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('statuses');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    name => {
        data_type => 'varchar',
        size      => 64,
    },
    is_initial => {
        data_type     => 'boolean',
        default_value => 0,
    },
    continues_request => {
        data_type     => 'boolean',
        default_value => 0,
    },
    reassigns_request => {
        data_type     => 'boolean',
        default_value => 0,
    },
    recycles_request => {
        data_type     => 'boolean',
        default_value => 0,
    },
    finishes_request => {
        data_type     => 'boolean',
        default_value => 0,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->add_unique_constraint(name => [ qw/name/ ]);

__PACKAGE__->has_many(
    actions => 'UFL::Workflow::Schema::Action',
    { 'foreign.status_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->resultset_class('UFL::Workflow::ResultSet::Status');

=head1 NAME

UFL::Workflow::Schema::Status - Status table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Status table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 uri_args

Return the list of URI path arguments needed to identify this status.

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
