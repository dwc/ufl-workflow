package UFL::Workflow::Schema::Document;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('documents');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    request_id => {
        data_type => 'integer',
    },
    # Refers to replacement document
    document_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    user_id => {
        data_type => 'integer',
    },
    name => {
        data_type => 'varchar',
        size      => 128,
    },
    extension => {
        data_type => 'varchar',
        size      => 8,
    },
    type => {
        data_type => 'varchar',
        size      => 128,
    },
    md5 => {
        data_type => 'varchar',
        size      => 32,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    request => 'UFL::Workflow::Schema::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    replacement => 'UFL::Workflow::Schema::Document',
    'document_id',
    { join_type => 'left' },
);

__PACKAGE__->belongs_to(
    submitter => 'UFL::Workflow::Schema::User',
    'user_id',
);

__PACKAGE__->resultset_attributes({
    order_by => \q[me.update_time DESC, me.insert_time DESC],
});

=head1 NAME

UFL::Workflow::Schema::Document - Document table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Document table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 path

Return the obfuscated path for this document (currently based on MD5).

=cut

sub path {
    my ($self) = @_;

    # Based on Cache::FileCache
    my @path = unpack 'A2' x 2 . 'A*', $self->md5 . '.' . $self->extension;

    return @path;
}

=head2 uri_args

Return the list of URI path arguments needed to identify this
document.

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
