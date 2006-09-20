package UFL::Curriculum::Schema::Group;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

__PACKAGE__->table('groups');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    user_id => {
        data_type => 'integer',
    },
    name => {
        data_type => 'varchar',
        size      => 32,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->add_unique_constraint(name => [ qw/name/ ]);

__PACKAGE__->belongs_to(
    primary_contact => 'UFL::Curriculum::Schema::User',
    'user_id',
);

__PACKAGE__->has_many(
    roles => 'UFL::Curriculum::Schema::Role',
    { 'foreign.group_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

=head1 NAME

UFL::Curriculum::Schema::Group - Group table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Group table class for L<UFL::Curriculum::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
