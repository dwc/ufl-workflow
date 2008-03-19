package UFL::Workflow::Schema::Field;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('fields');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    process_id => {
        data_type => 'integer',
    },
    prev_field_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    next_field_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    name => {
        data_type => 'varchar',
        size      => 64,
    },
    description => {
        data_type => 'varchar',
        size      => 8192,
        is_nullable => 1,
    },
    type => {
        data_type => 'integer',
    },
    min_length => {
        data_type => 'integer',
        is_nullable => 1,
    },
    max_length => {
        data_type => 'integer',
        is_nullable => 1,
    },
    optional => {
        data_type     => 'boolean',
        default_vaule => '0',
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    process => 'UFL::Workflow::Schema::Process',
    'process_id',
);

__PACKAGE__->belongs_to(
    prev_field => 'UFL::Workflow::Schema::Field',
    'prev_field_id',
    { join_type => 'left' },
);

__PACKAGE__->belongs_to(
    next_field => 'UFL::Workflow::Schema::Field',
    'next_field_id',
    { join_type => 'left' },
);

__PACKAGE__->has_many(
    content => 'UFL::Workflow::Schema::FieldData',
    { 'foreign.field_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

=head1 NAME

UFL::Workflow::Schema::Field - Step table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Field table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 delete

Remove the specified field from the chain.  If any content are
associated with this field, we refuse to remove it to avoid leaving
requests in an inconsistent state.

=cut

sub delete {
    my ($self, @args) = @_;

    $self->throw_exception('Process cannot be edited')
        unless $self->process->is_editable;
    $self->throw_exception('Field has associated content')
        if $self->content->count > 0;

    my $next = $self->next::can;
    $self->result_source->schema->txn_do(sub {
        my $prev_field = $self->prev_field;
        my $next_field = $self->next_field;

        # Beginning of chain
        if ($prev_field) {
            $prev_field->next_field($next_field);
            $prev_field->update;
        }

        # End of chain
        if ($next_field) {
            $next_field->prev_field($prev_field);
            $next_field->update;
        }

        $next->($self, @args);
    });
}

=head2 move_up

Move this field up one in the chain.  If the field has associated
content or is the first in the process, an exception is thrown.

=cut

sub move_up {
    my ($self) = @_;

    $self->throw_exception('Process cannot be edited')
        unless $self->process->is_editable;
    $self->throw_exception('Field has associated content')
        if $self->content->count > 0;

    my $prev_field      = $self->prev_field;
    my $prev_prev_field = $prev_field->prev_field;
    my $next_field      = $self->next_field;

    $self->throw_exception('Field appears to be first in chain')
        unless $prev_field;

    $self->result_source->schema->txn_do(sub {
        if ($prev_prev_field) {
            $prev_prev_field->next_field($self);
            $prev_prev_field->update;
        }

        $prev_field->prev_field($self);
        $prev_field->next_field($next_field);
        $prev_field->update;

        $self->prev_field($prev_prev_field);
        $self->next_field($prev_field);
        $self->update;

        if ($next_field) {
            $next_field->prev_field($prev_field);
            $next_field->update;
        }
    });
}

=head2 move_down

Move this field down one in the chain.  If the field has associated
content or is the first in the process, an exception is thrown.

=cut

sub move_down {
    my ($self) = @_;

    $self->throw_exception('Process cannot be edited')
        unless $self->process->is_editable;
    $self->throw_exception('Field has associated content')
        if $self->content->count > 0;

    my $prev_field      = $self->prev_field;
    my $next_field      = $self->next_field;
    my $next_next_field = $next_field->next_field;

    $self->throw_exception('Field appears to be last in chain')
        unless $next_field;

    $self->result_source->schema->txn_do(sub {
        if ($prev_field) {
            $prev_field->next_field($next_field);
            $prev_field->update;
        }

        $self->prev_field($next_field);
        $self->next_field($next_next_field);
        $self->update;

        $next_field->prev_field($prev_field);
        $next_field->next_field($self);
        $next_field->update;

        if ($next_next_field) {
            $next_next_field->prev_field($self);
            $next_next_field->update;
        }
    });
}

=head2 uri_args

Return the list of URI path arguments needed to identify this field.

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
