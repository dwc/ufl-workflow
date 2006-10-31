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
        size        => 1024,
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
);

__PACKAGE__->has_many(
    action_groups => 'UFL::Workflow::Schema::ActionGroup',
    { 'foreign.action_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many('groups', 'action_groups', 'group');

=head1 NAME

UFL::Workflow::Schema::Action - Action table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Action table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 update_status

Update the status of this action, driving the process to the next
step.

=cut

sub update_status {
    my ($self, $values) = @_;

    my $status  = delete $values->{status};
    my $actor   = delete $values->{actor};
    my $group   = delete $values->{group};
    my $comment = delete $values->{comment};

    $self->throw_exception('You must provide a status')
        unless blessed $status and $status->isa('UFL::Workflow::Schema::Status');
    $self->throw_exception('You must provide an actor')
        unless blessed $actor and $actor->isa('UFL::Workflow::Schema::User');
    $self->throw_exception('Actor cannot decide on this action')
        unless $actor->can_decide_on($self);
    $self->throw_exception('Decision already made')
        unless $self->status->is_initial;

    my $request = $self->request;
    $self->result_source->schema->txn_do(sub {
        $self->status($status);
        $self->actor($actor);
        $self->comment($comment);
        $self->update;

        my $action;
        if ($status->continues_request) {
            my $step = $request->next_step;
            if ($step) {
                $action = $request->add_action($step);
            }
        }
        elsif ($status->finishes_request) {
            # Done
        }
        else {
            # Add a copy of the current step
            $action = $request->add_action($self->step);
        }

        if ($action) {
            $action->assign_to_group($group);

            # Update pointers
            $action->prev_action($self);
            $action->update;

            $self->next_action($action);
            $self->update;
        }
    });
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
