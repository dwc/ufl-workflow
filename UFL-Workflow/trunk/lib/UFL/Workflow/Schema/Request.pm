package UFL::Workflow::Schema::Request;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Digest::MD5 ();
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
    title => {
        data_type => 'varchar',
        size      => 64,
    },
    description => {
        data_type => 'varchar',
        size      => 1024,
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
    documents => 'UFL::Workflow::Schema::Document',
    { 'foreign.request_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

=head1 NAME

UFL::Workflow::Schema::Request - Request table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Request table class for L<UFL::Workflow::Schema>.

=head1 METHODS

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

=head2 current_step

Return the L<UFL::Workflow::Schema::Step> in the
L<UFL::Workflow::Schema::Process> associated with the current
L<UFL::Workflow::Schema::Action> on this request.

=cut

sub current_step {
    my ($self) = @_;

    return $self->current_action->step;
}

=head2 next_step

Return the next L<UFL::Workflow::Schema::Step> associated with
this request.

=cut

sub next_step {
    my ($self) = @_;

    my $action = $self->current_action;

    my $step = $self->current_step;
    while ($step and $step->prev_step_id != $action->step_id) {
        $step = $step->next_step;
    }

    return $step;
}

=head2 is_open

Return true if this request is open, i.e., the current step is pending
a decision.

=cut

sub is_open {
    my ($self) = @_;

    return $self->current_action->status->is_initial;
}

=head2 initial_status

Return the L<UFL::Workflow::Schema::Status> used as the initial status
for new L<UFL::Workflow::Schema::Action>s on this request.

=cut

sub initial_status {
    my ($self) = @_;

    my $initial_status = $self->result_source->schema->resultset('Status')->search({ is_initial => 1 })->first;
    $self->throw_exception('Could not find initial status')
        unless $initial_status;

    return $initial_status;
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

    my $step = $self->current_step;
    if ($status->continues_request) {
        $step = $self->next_step;
    }
    elsif ($status->finishes_request) {
        $step = undef;
    }

    my @groups;
    if ($step) {
        @groups = $step->role->groups;
    }

    return @groups;
}

=head2 add_action

Add a new action to this request corresponding to the specified
L<UFL::Workflow::Schema::Step>.

=cut

sub add_action {
    my ($self, $step) = @_;

    $self->throw_exception('You must provide a step for the action')
        unless blessed $step and $step->isa('UFL::Workflow::Schema::Step');

    my $initial_status = $self->initial_status;

    my $action;
    $self->result_source->schema->txn_do(sub {
        $action = $self->actions->find_or_create({
            step_id   => $step->id,
            status_id => $initial_status->id,
        });
    });

    return $action;
}

=head2 add_document

Add a new L<UFL::Workflow::Schema::Document> to this request.

=cut

sub add_document {
    my ($self, $values) = @_;

    $self->throw_exception('You must provide a title and extension')
        unless ref $values eq 'HASH' and $values->{title} and $values->{extension};

    my $user              = delete $values->{user};
    my $contents          = delete $values->{contents};
    my $destination       = delete $values->{destination};
    my $replaced_document = delete $values->{replaced_document};

    $self->throw_exception('You must provide a user')
        unless blessed $user and $user->isa('UFL::Workflow::Schema::User');
    $self->throw_exception('You must provide the document contents')
        unless $contents;
    $self->throw_exception('You must provide a destination directory')
        unless blessed $destination and $destination->isa('Path::Class::Dir');
    $self->throw_exception('User cannot manage request')
        unless $user->can_manage($self);

    my $document;
    $self->result_source->schema->txn_do(sub {
        my $length = $self->documents->result_source->column_info('title')->{size};
        my $title  = substr(delete $values->{title}, 0, $length);
        my $md5    = Digest::MD5::md5_hex($contents);

        $document = $self->documents->find_or_create({
            %$values,
            title => $title,
            md5   => $md5,
        });

        if ($replaced_document) {
            $replaced_document->document_id($document->id);
            $replaced_document->update;
        }

        # Copy the file into the destination
        my $filename = $destination->file(@{ $document->uri_args });
        $filename->parent->mkpath;
        my $fh = IO::File->new($filename, 'w') or die "Error opening $filename: $!";
        $fh->binmode(':raw');
        $fh->print($contents);
        $fh->close;
    });

    return $document;
}

=head2 update_status

Update the status of the current L<UFL::Workflow::Schema::Action>.

=cut

sub update_status {
    my ($self, $values) = @_;

    die 'Request is not open' unless $self->is_open;

    $self->current_action->update_status($values);
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
