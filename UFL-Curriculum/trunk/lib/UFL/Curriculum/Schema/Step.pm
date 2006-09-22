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
    group_id => {
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
    group_role => 'UFL::Curriculum::Schema::GroupRole',
    {
        'foreign.role_id' => 'self.role_id',
        'foreign.group_id' => 'self.group_id',
    },
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

=head1 METHODS

=head2 group

Return the L<UFL::Curriculum::Schema::Group> associated with this
step.

=cut

sub group {
    my $self = shift;

    $self->group_role->group(@_);
}

=head2 role

Return the L<UFL::Curriculum::Schema::Role> associated with this
step.

=cut

sub role {
    my $self = shift;

    $self->group_role->role(@_);
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
