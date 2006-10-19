package UFL::Workflow::Schema::Group;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('groups');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    parent_group_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    name => {
        data_type => 'varchar',
        size      => 32,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    parent_group => 'UFL::Workflow::Schema::Group',
    { 'foreign.id' => 'self.parent_group_id' },
);

__PACKAGE__->has_many(
    child_groups => 'UFL::Workflow::Schema::Group',
    { 'foreign.parent_group_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0, order_by => 'name' },
);

__PACKAGE__->has_many(
    group_roles => 'UFL::Workflow::Schema::GroupRole',
    { 'foreign.group_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many('roles', 'group_roles', 'role');

__PACKAGE__->resultset_class('UFL::Workflow::ResultSet::Group');

=head1 NAME

UFL::Workflow::Schema::Group - Group table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Group table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 update

Check that the group ID is not the same as the parent group ID.  If
the check passes, update the record.

=cut

sub update {
    my $self = shift;

    $self->throw_exception('Parent group cannot be the same as the group')
        if $self->id == $self->parent_group_id;

    $self->next::method(@_);
}

=head2 add_role

Add a role to this group.

=cut

sub add_role {
    my ($self, $values) = @_;

    my $role;
    $self->result_source->schema->txn_do(sub {
        $role = $self->result_source->schema->resultset('Role')->find_or_create($values);
        $self->add_to_roles($role);
    });

    return $role;
}

=head2 uri_args

Return the list of URI path arguments needed to identify this group.

=cut

sub uri_args {
    my ($self) = @_;

    return $self->id;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
