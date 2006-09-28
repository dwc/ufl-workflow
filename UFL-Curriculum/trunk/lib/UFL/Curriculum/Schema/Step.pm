package UFL::Curriculum::Schema::Step;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

__PACKAGE__->table('steps');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    process_id => {
        data_type => 'integer',
    },
    role_id => {
        data_type => 'integer',
    },
    prev_step_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    next_step_id => {
        data_type => 'integer',
        is_nullable => 1,
    },
    name => {
        data_type => 'varchar',
        size      => 32,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    process => 'UFL::Curriculum::Schema::Process',
    'process_id',
);

__PACKAGE__->belongs_to(
    role => 'UFL::Curriculum::Schema::Role',
    'role_id',
);

__PACKAGE__->belongs_to(
    prev_step => 'UFL::Curriculum::Schema::Step',
    'prev_step_id',
    { join_type => 'left' },
);

__PACKAGE__->belongs_to(
    next_step => 'UFL::Curriculum::Schema::Step',
    'next_step_id',
    { join_type => 'left' },
);

__PACKAGE__->has_many(
    actions => 'UFL::Curriculum::Schema::Action',
    { 'foreign.step_id' => 'self.id' },
);

=head1 NAME

UFL::Curriculum::Schema::Step - Step table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Step table class for L<UFL::Curriculum::Schema>.

=head1 METHODS

=head2 delete

Remove the specified step from the chain.  If any actions are
associated with this step, we refuse to remove it to avoid leaving
requests in an inconsistent state.

=cut

sub delete {
    my ($self, @args) = @_;

    $self->throw_exception('Step has associated actions')
        if $self->actions->count > 0;

    my $schema = $self->result_source->schema;
    eval {
        $schema->txn_begin;

        my $prev_step = $self->prev_step;
        my $next_step = $self->next_step;

        # Beginning of chain
        if ($prev_step) {
            $prev_step->next_step($next_step);
            $prev_step->update;
        }

        # End of chain
        if ($next_step) {
            $next_step->prev_step($prev_step);
            $next_step->update;
        }

        $self->next::method(@args);
        $schema->txn_commit;
    };
    if (my $error = $@) {
        eval { $schema->txn_rollback; $self->throw_exception($error) };
        $self->throw_exception($@) if $@;
    }
}

=head2 uri_args

Return the list of URI path arguments needed to identify this step.

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
