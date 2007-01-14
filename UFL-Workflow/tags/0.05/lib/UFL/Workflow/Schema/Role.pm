package UFL::Workflow::Schema::Role;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('roles');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    name => {
        data_type => 'varchar',
        size      => 32,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->add_unique_constraint(name => [ qw/name/ ]);

__PACKAGE__->has_many(
    steps => 'UFL::Workflow::Schema::Step',
    { 'foreign.role_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    group_roles => 'UFL::Workflow::Schema::GroupRole',
    { 'foreign.role_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    user_group_roles => 'UFL::Workflow::Schema::UserGroupRole',
    { 'foreign.role_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many('groups', 'group_roles', 'group');
__PACKAGE__->many_to_many('users', 'user_group_roles', 'actor');

=head1 NAME

UFL::Workflow::Schema::Role - Role table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Role table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 uri_args

Return the list of URI path arguments needed to identify this role.

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
