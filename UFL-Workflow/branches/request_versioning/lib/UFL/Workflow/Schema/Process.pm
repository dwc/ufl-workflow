package UFL::Workflow::Schema::Process;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Scalar::Util qw/blessed/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('processes');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    user_id => {
        data_type => 'integer',
    },
    name => {
        data_type => 'varchar',
        size      => 64,
    },
    description => {
        data_type   => 'varchar',
        size        => 8192,
        is_nullable => 1,
    },
    enabled => {
        data_type     => 'boolean',
        default_value => 0,
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
    fields => 'UFL::Workflow::Schema::Field',
    { 'foreign.process_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    requests => 'UFL::Workflow::Schema::Request',
    { 'foreign.process_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->resultset_attributes({
    order_by => 'me.name',
});

=head1 NAME

UFL::Workflow::Schema::Process - Process table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Process table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 first_field

Return the first L<UFL::Workflow::Schema::Field> associated with this
process.

=cut

sub first_field {
    my $self = shift;

    my $first_field = $self->fields->search({ prev_field_id => undef })->first;

    return $first_field;
}

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

=head2 last_field

Return the last L<UFL::Workflow::Schema::Field> associated with this
process.

=cut

sub last_field {
    my $self = shift;

    my $last_field = $self->fields->search({ next_field_id => undef })->first;

    return $last_field;
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
    my ($self, $name, $role) = @_;

    $self->throw_exception('You must provide a name for the step')
        unless $name;
    $self->throw_exception('You must provide a role')
        unless blessed $role and $role->isa('UFL::Workflow::Schema::Role');
    $self->throw_exception('Process cannot be edited')
        unless $self->is_editable;

    my $step;
    $self->result_source->schema->txn_do(sub {
        my $last_step = $self->last_step;

        $step = $self->steps->create({
            name    => $name,
            role_id => $role->id,
        });

        if ($last_step) {
            $step->prev_step($last_step);
            $step->update;

            $last_step->next_step($step);
            $last_step->update;
        }
    });

    return $step;
}

=head2 add_field

Add a new field to the end of the chain for this process.

=cut

sub add_field {
    my ($self, $name, $description, $type, $min_length, $max_length, $optional) = @_;

    $self->throw_exception('You must provide a name for the field')
        unless $name;
    $self->throw_exception('Process cannot be edited')
        unless $self->is_editable;

    my $field;
    $self->result_source->schema->txn_do(sub {
        my $last_field = $self->last_field;

        $field = $self->fields->create({
            name        => $name,
	    description => $description,
	    type        => $type,
	    min_length  => $min_length,
	    max_length  => $max_length,
	    optional    => $optional,
        });

        if ($last_field) {
            $field->prev_field($last_field);
            $field->update;

            $last_field->next_field($field);
            $last_field->update;
        }
    });

    return $field;
}

=head2 validate_field 

Validates the extra field of this process

=cut
sub validate_field {
    my ($self, $c, $field) = @_;
    
    # 1. form yml query based on database.
    # 2. form yml messages for errors.
    # 3. validate the forms.

    my %messages;
    my @validations;

    $messages{ $field->id } = $field->get_message();
    push @validations, $field->get_validation_condition();

    my $validator = FormValidator::Simple->new;
    $validator->set_messages({ edit_field => {%messages} });
    
    my $result = $validator->check( $c->req => [@validations] );
    $c->stash(
         field_errors => $result->messages("edit_field"),
         fillform     => 1,
    );
    return $result;
}

=head2 validate_fields 

Validates the extra fields of this process

=cut
sub validate_fields {
    my ($self, $c) = @_;
    
    # 1. form yml query based on database.
    # 2. form yml messages for errors.
    # 3. validate the forms.

    my $process = $c->stash->{process};
    my %messages;
    my @validations;
    my $field = $process->first_field;

    while ($field) {
        $messages{ $field->id } = $field->get_message();
	push @validations, $field->get_validation_condition();
	$field = $field->next_field;
    }

    my $validator = FormValidator::Simple->new;
    $validator->set_messages({ add_request => {%messages} });
    
    #$c->log->_dump([@validations]);
    my $result = $validator->check( $c->req => [@validations] );
    $c->stash(
         field_errors => $result->messages("add_request"),
         fillform     => 1,
    );
    return $result;
}

=head2 add_request

Add a request that follows this process.

=cut

sub add_request {
    my ($self, $user, $initial_group) = @_;

    $self->throw_exception('You must provide a user')
        unless blessed $user and $user->isa('UFL::Workflow::Schema::User');
    $self->throw_exception('You must provide a group')
        unless blessed $initial_group and $initial_group->isa('UFL::Workflow::Schema::Group');

    my $request;
    $self->result_source->schema->txn_do(sub {
        $request = $self->requests->create({
            user_id     => $user->id,
        });
	$request->create_version();
        my $action = $request->add_action($self->first_step);
        $action->assign_to_group($initial_group);
    });

    return $request;
}

=head2 uri_args

Return the list of URI path arguments needed to identify this process.

=cut

sub uri_args {
    my ($self) = @_;

    return [ $self->id ];
}

=head2 to_json

Return a hash suitable for conversion to JSON which represents this
process.

=cut

sub to_json {
    my ($self) = @_;

    my $process = {
        id      => $self->id,
        name    => $self->name,
        enabled => int($self->enabled),
    };

    return $process;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
