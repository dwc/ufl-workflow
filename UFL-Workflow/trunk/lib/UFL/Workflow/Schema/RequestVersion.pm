package UFL::Workflow::Schema::RequestVersion;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('request_versions');
__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 0,
    },
    request_id => {
        data_type         => 'integer',
    },
    process_id => {
        data_type         => 'integer',
    },
    user_id => {
        data_type         => 'integer',
    },
    title => {
        data_type         => 'varchar',
        size              => 64,
    },
    description => {
        data_type         => 'varchar',
        size              => 8192,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    process => 'UFL::Workflow::Schema::Process',
    'process_id',
);

__PACKAGE__->belongs_to(
    request => 'UFL::Workflow::Schema::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    submitter => 'UFL::Workflow::Schema::User',
    'user_id',
);

__PACKAGE__->has_many(
    actions => 'UFL::Workflow::Schema::Action',
    { 'foreign.requestVersion_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    documents => 'UFL::Workflow::Schema::Document',
    { 'foreign.requestVersion_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->resultset_attributes({
    order_by => \q[me.update_time DESC, me.insert_time DESC],
});

=head1 NAME

UFL::Workflow::Schema::RequestVersion - RequestVersion table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

RequestVersion table class for L<UFL::Workflow::Schema>.


=head2 uri_args

Return the list of URI path arguments needed to identify this requestVersion.

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
