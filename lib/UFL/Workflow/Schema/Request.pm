package UFL::Workflow::Schema::Request;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Digest::MD5 ();
use MIME::Type;
use MIME::Types ();
use Path::Class::File ();
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
        size      => 8192,
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

    return $self->result_source->schema->resultset('Group')->search(
        {
            'role.id' => $step ? $step->role->id : 0,
        },
        {
            join     => [ { group_roles => 'role' } ],
            order_by => 'me.name',
        },
    );
}

=head2 default_group_for_status

Find the assigned group from the previous step, for having an easy
default when recycling.  Returns C<undef> when no reasonable default
can be found.

Note: This is intended to be advisory; no verification is done that
the group is valid for the status.

=cut

sub default_group_for_status {
    my ($self, $status) = @_;

    my $default_group = undef;

    # Default to the parent group
    my $current_group = $self->current_action->groups->first;
    if (my $parent_group = $current_group->parent_group) {
        $default_group = $parent_group;
    }

    # Recycling sends the request back to the previous step
    if (my $prev_step = $self->prev_step) {
        # Find an action in the sequence corresponding to the previous step
        # (not necessarily the previous action; see e.g. https://approval.ufl.edu/requests/2907)
        my $action = $self->prev_action;
        while (my $prev_action = $action->prev_action
               and $action->step->id != $prev_step->id) {
            $action = $prev_action;
        }

        $default_group = $action->groups->first;
    }

    return $default_group;
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

=head2 add_document

Add a new L<UFL::Workflow::Schema::Document> to this request.

=cut

sub add_document {
    my ($self, $user, $filename, $contents, $destination, $replaced_document_id) = @_;

    $self->throw_exception('You must provide a filename, the contents, and a destination directory')
        unless $filename and $contents and $destination;
    $self->throw_exception('You must provide a user')
        unless blessed $user and $user->isa('UFL::Workflow::Schema::User');
    $self->throw_exception('User cannot manage request')
        unless $user->can_manage($self);

    my ($name, $extension) = ($filename =~ /(.+)\.([^.]+)$/);
    $extension = lc $extension;

    # XXX: Remove when added to MIME::Types
    my $docx = MIME::Type->new(
        type       => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        extensions => ['docx'],
    );

    my $types = MIME::Types->new;
    $types->addType($docx);

    my $type = $types->mimeTypeOf($extension);
    die "Unknown type for extension [$extension]" unless $type;

    my $document;
    $self->result_source->schema->txn_do(sub {
        my $length = $self->documents->result_source->column_info('name')->{size};

        $document = $self->documents->create({
            name      => substr($name, 0, $length),
            user_id   => $user->id,
            extension => $extension,
            type      => $type,
            md5       => Digest::MD5::md5_hex($contents),
        });

        if ($replaced_document_id) {
            my $replaced_document = $self->documents->find($replaced_document_id);
            die 'Replaced document not found' unless $replaced_document;

            $replaced_document->document_id($document->id);
            $replaced_document->update;
        }

        # Copy the file into the destination
        my $filename = Path::Class::File->new($destination, $document->path);
        $filename->parent->mkpath;
        my $fh = IO::File->new($filename, 'w') or die "Error opening $filename: $!";
        $fh->binmode(':raw');
        $fh->print($contents);
        $fh->close;
    });

    return $document;
}

=head2 active_documents

Return a resultset of active documents without an id.

=cut

sub active_documents {
    my ($self) = @_;

    my $active_documents = $self->documents->search({ 
        document_id => undef,
        active      => 1, },
        { order_by    => 'insert_time' },
    );

    return $active_documents;
}

=head2 removed_documents

Return a resultset of inactive documents that do not have an id.

=cut

sub removed_documents {
    my ($self) = @_;

    my $removed_documents = $self->documents->search({
        document_id => undef,
        active      => 0, },
        { order_by    => 'insert_time' },
    );

    return $removed_documents;
}


=head2 replaced_documents

Return a resultset of inactive documents that have an id.

=cut

sub replaced_documents {
    my ($self) = @_;

    my $replaced_documents = $self->documents->search(
        { document_id => { '!=' => undef }, 
          active      => 1 },
        { order_by    => 'insert_time' },
    );

    return $replaced_documents;
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

=head2 add_version

Add a new L<UFL::Workflow::Schema::RequestVersion> to this request.

=cut

sub add_version {
    my ($self, $user) = @_;

    $self->throw_exception('You must provide a request')
        unless $self;
    $self->throw_exception('You must provide a user')
        unless blessed $user and $user->isa('UFL::Workflow::Schema::User');
    $self->throw_exception('User cannot manage request')
        unless $user->can_manage($self);

    my $version;
    $self->result_source->schema->txn_do(sub {
        my $num = $self->versions->get_column('num')->max;
        $num++;

        $version = $self->versions->create({
	    num         => $num,
            user_id     => $user->id,
            title       => $self->title,
            description => $self->description,
        });

    });

    return $version;
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
