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
        size      => 64,
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

__PACKAGE__->has_many(
    user_group_roles => 'UFL::Workflow::Schema::UserGroupRole',
    { 'foreign.group_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    action_groups => 'UFL::Workflow::Schema::ActionGroup',
    { 'foreign.group_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many('roles', 'group_roles', 'role');
__PACKAGE__->many_to_many('actions', 'action_groups', 'action');

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
    my ($self, @args) = @_;

    # Not using txn_do for $self->next::method
    my $schema = $self->result_source->schema;
    eval {
        $schema->txn_begin;

        $self->next::method(@args);

        $self->throw_exception('Parent group cannot be the same as the group')
            if $self->id == $self->parent_group_id;
        $schema->txn_commit;
    };
    if (my $error = $@) {
        eval { $schema->txn_rollback; $self->throw_exception($error) };
        $self->throw_exception($@) if $@;
    }
}

=head2 has_role

Return true if this group has the specified
L<UFL::Workflow::Schema::Role>.

=cut

sub has_role {
    my ($self, $role) = @_;

    $self->throw_exception('You must provide a role')
        unless blessed $role and $role->isa('UFL::Workflow::Schema::Role');

    my @roles = $self->roles;

    return grep { $role->id == $_->id } @roles;
}

=head2 can_decide_on

Return true if this group can decide on the specified
L<UFL::Workflow::Schema::Action>.

=cut

sub can_decide_on {
    my ($self, $action) = @_;

    $self->throw_exception('You must provide an action')
        unless blessed $action and $action->isa('UFL::Workflow::Schema::Action');

    return ($action->status->is_initial and $self->has_role($action->step->role));
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

    return [ $self->id ];
}

=head2 to_json

Return a hash suitable for conversion to JSON which represents this
group.

=cut

sub to_json {
    my ($self) = @_;

    return { id => $self->id, name => $self->name };
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
