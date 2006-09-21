package UFL::Curriculum::Schema::Document;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

__PACKAGE__->table('documents');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    request_id => {
        data_type => 'integer',
    },
    replacement_document_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    md5 => {
        data_type => 'varchar',
        size      => 32,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    request => 'UFL::Curriculum::Schema::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    replacement_document => 'UFL::Curriculum::Schema::Document',
    'replacement_document_id',
    { join_type => 'left' },
);

=head1 NAME

UFL::Curriculum::Schema::Document - Document table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Document table class for L<UFL::Curriculum::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
