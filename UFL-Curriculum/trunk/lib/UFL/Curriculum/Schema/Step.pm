package UFL::Curriculum::Schema::Step;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

__PACKAGE__->table('steps');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    process_id => {
        data_type => 'integer',
    },
    role_id => {
        data_type => 'integer',
    },
    prev_step_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    next_step_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    name => {
        data_type => 'varchar',
        size      => 32,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    process => 'UFL::Curriculum::Schema::Process',
    'process_id',
);

__PACKAGE__->belongs_to(
    role => 'UFL::Curriculum::Schema::Role',
    'role_id',
);

__PACKAGE__->belongs_to(
    prev_step => 'UFL::Curriculum::Schema::Step',
    'prev_step_id',
    { join_type => 'left' },
);

__PACKAGE__->belongs_to(
    next_step => 'UFL::Curriculum::Schema::Step',
    'next_step_id',
    { join_type => 'left' },
);

=head1 NAME

UFL::Curriculum::Schema::Step - Step table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Step table class for L<UFL::Curriculum::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
