package UFL::Curriculum::Schema::Request;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

__PACKAGE__->table('requests');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    process_id => {
        data_type => 'integer',
    },
    user_id => {
        data_type => 'integer',
    },
    title => {
        data_type => 'varchar',
        size      => 32,
    },
    description => {
        data_type => 'varchar',
        size      => 1024,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    process => 'UFL::Curriculum::Schema::Process',
    'process_id',
);

__PACKAGE__->belongs_to(
    submitter => 'UFL::Curriculum::Schema::User',
    'user_id',
);

__PACKAGE__->has_many(
    actions => 'UFL::Curriculum::Schema::Action',
    { 'foreign.request_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    documents => 'UFL::Curriculum::Schema::Document',
    { 'foreign.request_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

=head1 NAME

UFL::Curriculum::Schema::Request - Request table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Request table class for L<UFL::Curriculum::Schema>.

=head1 METHODS

=head2 add_action

Add a new action to this request.

=cut

sub add_action {
    my ($self, $values) = @_;

    $self->throw_exception('You must provide a step for the action')
        unless ref $values eq 'HASH' and $values->{step_id};

    my $initial_status = $self->result_source->schema->resultset('Status')->search({ is_initial => 1 })->first;
    $self->throw_exception('Could not find initial status')
        unless $initial_status;

    my $new_action;
    $self->result_source->schema->txn_do(sub {
        my %values = (
             status_id => $initial_status->id,
             %$values,
        );

        $new_action = $self->actions->find_or_create(\%values);
    });

    return $new_action;
}

=head2 uri_args

Return the list of URI path arguments needed to identify this request.

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
