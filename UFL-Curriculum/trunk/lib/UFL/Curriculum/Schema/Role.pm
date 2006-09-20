package UFL::Curriculum::Schema::Role;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

__PACKAGE__->table('roles');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    group_id => {
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
    group => 'UFL::Curriculum::Schema::Group',
    'group_id',
);

__PACKAGE__->has_many(
    user_roles => 'UFL::Curriculum::Schema::UserRole',
    { 'foreign.role_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    steps => 'UFL::Curriculum::Schema::Step',
    { 'foreign.role_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

=head1 NAME

UFL::Curriculum::Schema::Role - Role table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Role table class for L<UFL::Curriculum::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
