package UFL::Workflow::Schema::Request;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Scalar::Util qw/blessed/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('requests');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    process_id => {
        data_type => 'integer',
    },
    user_id => {
        data_type => 'integer',
    },    
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    process => 'UFL::Workflow::Schema::Process',
    'process_id',
);

__PACKAGE__->belongs_to(
    submitter => 'UFL::Workflow::Schema::User',
    'user_id',
);

__PACKAGE__->has_many(
    actions => 'UFL::Workflow::Schema::Action',
    { 'foreign.request_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    versions => 'UFL::Workflow::Schema::RequestVersion',
    { 'foreign.request_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->resultset_attributes({
    order_by => \q[me.update_time DESC, me.insert_time DESC],
});

=head1 NAME

UFL::Workflow::Schema::Request - Request table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Request table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 current_version

Return the current version.

=cut

sub current_version {
    my ($self) = @_;
   
    if ( my $cur_version = $self->versions->search({ request_id => $self->id })) {
        return $cur_version->first;
    }    
}

=head2 version

Return the version.

=cut

sub version {
    my ($self, $version_num) = @_;
   
    if ( my $version = $self->versions->search({
        request_id => $self->id,
        version    => $version_num,
     })) {
        return $version->first;
    }    
}

=head2 all_version_count

Return all the versions count.

=cut

sub all_version_count {
    my ($self) = @_;
   
    return $self->versions->search({ request_id => $self->id })->count;    
}

=head2 create_version

get the current version and increate the version number and create a new version.

=cut

sub create_version{
    my ($self, $user_id) = @_;

    my $version_number = 1;
    
    if ( $self->current_version ) {
        $version_number = $self->current_version->version + 1;
    }
    
    $self->result_source->schema->txn_do(sub {
        $self->versions->create({
            request_id => $self->id,
            version    => $version_number,
            user_id    => $user_id,
        });
    });
}

=head2 first_action

Return the first L<UFL::Workflow::Schema::Action> entered for this
request, i.e., the earliest L<UFL::Workflow::Schema::Action> in the
L<UFL::Workflow::Schema::Process>.

=cut

sub first_action {
    my ($self) = @_;

    my $first_action = $self->actions->search({ prev_action_id => undef })->first;

    return $first_action;
}

=head2 current_action

Return the current L<UFL::Workflow::Schema::Action> entered for this
request, i.e., the latest L<UFL::Workflow::Schema::Action> in the
L<UFL::Workflow::Schema::Process>.

=cut

sub current_action {
    my ($self) = @_;

    my $current_action = $self->actions->search({ next_action_id => undef })->first;

    return $current_action;
}

=head2 prev_action

Return the previous L<UFL::Workflow::Schema::Action> entered for this
request.

=cut

sub prev_action {
    my ($self) = @_;

    return $self->current_action->prev_action;
}

=head2 first_step

Return the L<UFL::Workflow::Schema::Step> in the
L<UFL::Workflow::Schema::Process> associated with the first
L<UFL::Workflow::Schema::Action> on this request.

=cut

sub first_step {
    my ($self) = @_;

    return $self->first_action->step;
}

=head2 current_step

Return the L<UFL::Workflow::Schema::Step> in the
L<UFL::Workflow::Schema::Process> associated with the current
L<UFL::Workflow::Schema::Action> on this request.

=cut

sub current_step {
    my ($self) = @_;

    return $self->current_action->step;
}

=head2 prev_step

Return the prev L<UFL::Workflow::Schema::Step> associated with
this request.

=cut

sub prev_step {
    my ($self) = @_;

    return $self->current_step->prev_step;
}

=head2 next_step

Return the next L<UFL::Workflow::Schema::Step> associated with
this request.

=cut

sub next_step {
    my ($self) = @_;

    return $self->current_step->next_step;
}

sub title {
    my ($self) = @_;
    
    # first field will be sort of title.
    if ( my $first_field = $self->current_version->first_field_data) {
        return $first_field->value;
    }
    return "Empty Request";
}

=head2 is_open

Return true if this request is open, i.e., the current step is pending
a decision.

=cut

sub is_open {
    my ($self) = @_;

    return $self->current_action->status->is_initial;
}

=head2 groups_for_status

Return a list of L<UFL::Workflow::Schema::Group>s which can act on the
request given that the status of the current
L<UFL::Workflow::Schema::Action> is being set to the specified
L<UFL::Workflow::Schema::Status>.

=cut

sub groups_for_status {
    my ($self, $status) = @_;

    $self->throw_exception('You must provide a status')
        unless blessed $status and $status->isa('UFL::Workflow::Schema::Status');

    my $step;
    if ($status->continues_request) {
        $step = $self->next_step;
    }
    elsif ($status->reassigns_request) {
        $step = $self->current_step;
    }
    elsif ($status->recycles_request) {
        $step = $self->prev_step;
    }

    my @groups;
    if ($step) {
        @groups = $step->role->groups;
    }

    return @groups;
}

=head2 past_actors

Return a L<DBIx::Class::ResultSet> of L<UFL::Workflow::Schema::User>s
who have previously acted on this request.

=cut

sub past_actors {
    my ($self) = @_;

    my $past_actors = $self->actions
        ->related_resultset('actor')
        ->search(undef, { distinct => 1 });

    return $past_actors;
}

=head2 possible_actors

Return a L<DBIx::Class::ResultSet> of L<UFL::Workflow::Schema::User>s
who can act on this request in its current state.

=cut

sub possible_actors {
    my ($self) = @_;

    return $self->current_action->possible_actors;
}

=head2 add_action

Add a new action to this request corresponding to the specified
L<UFL::Workflow::Schema::Step>.

=cut

sub add_action {
    my ($self, $step) = @_;

    $self->throw_exception('You must provide a step for the action')
        unless blessed $step and $step->isa('UFL::Workflow::Schema::Step');

    my $initial_status = $self->result_source->schema->resultset('Status')->initial_status;

    my $action;
    $self->result_source->schema->txn_do(sub {
        $action = $self->actions->create({
            step_id   => $step->id,
            status_id => $initial_status->id,
        });
    });

    return $action;
}

=head2 update_status

Update the status of the current L<UFL::Workflow::Schema::Action>,
driving the request to the next step.

=cut

sub update_status {
    my ($self, $status, $actor, $group, $comment) = @_;

    $self->throw_exception('Request is not open')
        unless $self->is_open;

    my $current_action = $self->current_action;

    $self->throw_exception('You must provide a status')
        unless blessed $status and $status->isa('UFL::Workflow::Schema::Status');
    $self->throw_exception('You must provide an actor')
        unless blessed $actor and $actor->isa('UFL::Workflow::Schema::User');
    $self->throw_exception('Actor cannot decide on this action')
        unless $actor->can_decide_on($current_action);
    $self->throw_exception('Decision already made')
        unless $current_action->status->is_initial;

    $self->result_source->schema->txn_do(sub {
        $current_action->status($status);
        $current_action->actor($actor);
        $current_action->comment($comment);
        $current_action->update;

        my $step;
        if ($status->continues_request) {
            $step = $self->next_step;
        }
        elsif ($status->recycles_request) {
            # Recycling defaults to going back one step
            $step = $self->prev_step;

            # But allow recycling on the first step
            if ($self->current_step->id == $self->first_step->id) {
                $step = $self->current_step;
            }

            die 'No step found for recycle' unless $step;
        }
        elsif ($status->finishes_request) {
            # Done
        }
        else {
            # Add a copy of the current step
            $step = $self->current_step;
        }

        if ($step) {
            my $action = $self->add_action($step);

            # Fallback to current group if none was specified (e.g. tabling)
            $group ||= $current_action->groups->first;
            $action->assign_to_group($group);

            # Update pointers
            $action->prev_action($current_action);
            $action->update;

            $current_action->next_action($action);
            $current_action->update;
        }
    });
}

=head2 message_id

Return a string suitable for identifying this request in C<Message-Id>
or C<In-Reply-To> email headers.

=cut

sub message_id {
    my ($self, $base) = @_;

    return 'request-' . $self->id . '@' . $base;
}

=head2 subject

Return a string suitable for identifying this request in a C<Subject>
email header.

=cut

sub subject {
    my ($self, $message) = @_;

    return '[Request ' . $self->id . "] $message\"" . $self->title . '"';
}

=head2 uri_args

Return the list of URI path arguments needed to identify this request.

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
