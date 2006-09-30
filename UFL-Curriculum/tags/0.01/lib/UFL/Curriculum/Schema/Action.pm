package UFL::Curriculum::Schema::Action;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Scalar::Util qw/blessed/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

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
    request => 'UFL::Curriculum::Schema::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    step => 'UFL::Curriculum::Schema::Step',
    'step_id',
);

__PACKAGE__->belongs_to(
    status => 'UFL::Curriculum::Schema::Status',
    'status_id',
);

__PACKAGE__->belongs_to(
    prev_action => 'UFL::Curriculum::Schema::Action',
    'prev_action_id',
    { join_type => 'left' },
);

__PACKAGE__->belongs_to(
    next_action => 'UFL::Curriculum::Schema::Action',
    'next_action_id',
    { join_type => 'left' },
);

__PACKAGE__->belongs_to(
    actor => 'UFL::Curriculum::Schema::User',
    'user_id',
);

=head1 NAME

UFL::Curriculum::Schema::Action - Action table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Action table class for L<UFL::Curriculum::Schema>.

=head1 METHODS

=head2 update_status

Update the status of this action, driving the process to the next
step.

=cut

sub update_status {
    my ($self, $status, $actor, $comment) = @_;

    my $request = $self->request;

    $self->throw_exception('You must provide a status')
        unless blessed $status and $status->isa('UFL::Curriculum::Schema::Status');
    $self->throw_exception('You must provide an actor')
        unless blessed $actor and $actor->isa('UFL::Curriculum::Schema::User');
    $self->throw_exception('Decision already made')
        unless $self->status->is_initial;
    $self->throw_exception('Action does not appear to be the current one')
        unless $self->id == $request->current_action->id;

    $self->result_source->schema->txn_do(sub {
        $self->status($status);
        $self->actor($actor);
        $self->comment($comment);
        $self->update;

        my $action;
        if ($status->continues_request) {
            # Add the next step
            my $step = $request->current_step;
            while ($step and $step->prev_step_id != $self->step_id) {
                $step = $step->next_step;
            }

            if ($step) {
                $action = $request->add_action({ step_id => $step->id });
            }
        }
        elsif ($status->finishes_request) {
            # Done
        }
        else {
            # Add a copy of the current step
            $action = $request->add_action({ step_id => $self->step_id });
        }

        if ($action) {
            $self->next_action($action);
            $self->update;

            $action->prev_action($self);
            $action->update;
        }
    });
}

=head2 uri_args

Return the list of URI path arguments needed to identify this action.

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
