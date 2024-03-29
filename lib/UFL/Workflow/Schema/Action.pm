package UFL::Workflow::Schema::Action;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Scalar::Util qw/blessed/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('actions');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    request_id => {
        data_type => 'integer',
    },
    step_id => {
        data_type => 'integer',
    },
    status_id => {
        data_type => 'integer',
    },
    prev_action_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    next_action_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    user_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    comment => {
        data_type   => 'varchar',
        size        => 8192,
        is_nullable => 1,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    request => 'UFL::Workflow::Schema::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    step => 'UFL::Workflow::Schema::Step',
    'step_id',
);

__PACKAGE__->belongs_to(
    status => 'UFL::Workflow::Schema::Status',
    'status_id',
);

__PACKAGE__->belongs_to(
    prev_action => 'UFL::Workflow::Schema::Action',
    'prev_action_id',
    { join_type => 'left' },
);

__PACKAGE__->belongs_to(
    next_action => 'UFL::Workflow::Schema::Action',
    'next_action_id',
    { join_type => 'left' },
);

__PACKAGE__->belongs_to(
    actor => 'UFL::Workflow::Schema::User',
    'user_id',
    { join_type => 'left' },
);

__PACKAGE__->has_many(
    action_groups => 'UFL::Workflow::Schema::ActionGroup',
    { 'foreign.action_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many('groups', 'action_groups', 'group');
__PACKAGE__->many_to_many('group_roles', 'action_groups', 'group_role');
__PACKAGE__->many_to_many('user_group_roles', 'action_groups', 'user_group_role');

__PACKAGE__->resultset_class('UFL::Workflow::ResultSet::Action');

=head1 NAME

UFL::Workflow::Schema::Action - Action table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Action table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 statuses

Return a L<DBIx::Class::ResultSet> of valid statuses for this action.

=cut

sub statuses {
    my ($self) = @_;

    my $statuses = $self->result_source->schema->resultset('Status')->search(
        { is_initial => 0 },
        { order_by   => 'name' },
    );

    return $statuses;
}

=head2 group

Return the L<UFL::Workflow::Schema::Group> to which this action is
currently assigned.

=cut

sub group {
    my ($self) = @_;

    my $group;
    if (my $groups = $self->groups) {
        $group = $groups->first;
    }

    return $group;
}

=head2 assign_to_group

Assign this action to the specified L<UFL::Workflow::Schema::Group>.

=cut

sub assign_to_group {
    my ($self, $group) = @_;

    $self->throw_exception('You must provide a group')
        unless blessed $group and $group->isa('UFL::Workflow::Schema::Group');
    $self->throw_exception('Invalid group for step')
        unless $group->can_decide_on($self);

    $self->set_groups($group);
}

=head2 possible_actors

Return a L<DBIx::Class::ResultSet> of L<UFL::Workflow::Schema::User>s
who can act on this action.

=cut

sub possible_actors {
    my ($self) = @_;

    # Find the actors based on the assigned groups and the step-required role
    my $user_group_roles = $self->user_group_roles->search({
        role_id => $self->step->role->id,
    });

    my $possible_actors = $user_group_roles
        ->related_resultset('actor')
        ->search(undef, { distinct => 1 });

    return $possible_actors;
}

=head2 uri_args

Return the list of URI path arguments needed to identify this action.

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
