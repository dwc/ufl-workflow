package UFL::Workflow::Schema::Process;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('processes');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    user_id => {
        data_type => 'integer',
    },
    name => {
        data_type => 'varchar',
        size      => 32,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    creator => 'UFL::Workflow::Schema::User',
    'user_id',
);

__PACKAGE__->has_many(
    steps => 'UFL::Workflow::Schema::Step',
    { 'foreign.process_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    requests => 'UFL::Workflow::Schema::Request',
    { 'foreign.process_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

=head1 NAME

UFL::Workflow::Schema::Process - Process table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Process table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 first_step

Return the first L<UFL::Workflow::Schema::Step> associated with this
process.

=cut

sub first_step {
    my $self = shift;

    my $first_step = $self->steps->search({ prev_step_id => undef })->first;

    return $first_step;
}

=head2 last_step

Return the last L<UFL::Workflow::Schema::Step> associated with this
process.

=cut

sub last_step {
    my $self = shift;

    my $last_step = $self->steps->search({ next_step_id => undef })->first;

    return $last_step;
}

=head2 is_editable

Return true if this process is editable: if there are no associated
requests.

=cut

sub is_editable {
    my ($self) = @_;

    return ($self->requests->count == 0);
}

=head2 add_step

Add a new step to the end of the chain for this process.

=cut

sub add_step {
    my ($self, $values) = @_;

    $self->throw_exception('You must provide a role and name for the step')
        unless ref $values eq 'HASH' and $values->{role_id} and $values->{name};
    $self->throw_exception('Process cannot be edited')
        unless $self->is_editable;

    my $new_step;
    $self->result_source->schema->txn_do(sub {
        my $last_step = $self->last_step;

        my %values = %$values;
        $values{prev_step_id} = $last_step->id
            if $last_step;
        $new_step = $self->steps->find_or_create(\%values);

        if ($last_step) {
            $last_step->next_step_id($new_step->id);
            $last_step->update;
        }
    });

    return $new_step;
}

=head2 add_request

Add a request that follows this process.

=cut

sub add_request {
    my ($self, $values) = @_;

    $self->throw_exception('You must provide a user, title, description, and initial group for the request')
        unless ref $values eq 'HASH' and $values->{user_id} and $values->{title} and $values->{description} and $values->{group_id};

    my $group = $self->result_source->schema->resultset('Group')->find(delete $values->{group_id});
    $self->throw_exception('Coult not find group')
        unless $group;

    my $new_request;
    $self->result_source->schema->txn_do(sub {
        $new_request = $self->requests->find_or_create($values);

        my $action = $new_request->add_action({ step_id  => $self->first_step->id });
        $action->add_to_groups($group);
    });

    return $new_request;
}

=head2 uri_args

Return the list of URI path arguments needed to identify this process.

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
