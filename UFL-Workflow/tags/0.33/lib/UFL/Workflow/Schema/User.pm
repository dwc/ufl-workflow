package UFL::Workflow::Schema::User;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Class::C3;
use Scalar::Util qw/blessed/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('users');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    username => {
        data_type => 'varchar',
        size      => 16,
    },
    email => {
        data_type => 'varchar',
        size      => 64,
    },
    wants_email => {
        data_type     => 'boolean',
        default_value => 1,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->add_unique_constraint(username => [ qw/username/ ]);

__PACKAGE__->has_many(
    processes => 'UFL::Workflow::Schema::Process',
    { 'foreign.user_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    requests => 'UFL::Workflow::Schema::Request',
    { 'foreign.user_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    actions => 'UFL::Workflow::Schema::Action',
    { 'foreign.user_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->has_many(
    user_group_roles => 'UFL::Workflow::Schema::UserGroupRole',
    { 'foreign.user_id' => 'self.id' },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many('group_roles', 'user_group_roles', 'group_role');
__PACKAGE__->many_to_many('groups', 'user_group_roles', 'group');
__PACKAGE__->many_to_many('roles', 'user_group_roles', 'role');

__PACKAGE__->resultset_class('UFL::Workflow::ResultSet::User');

=head1 NAME

UFL::Workflow::Schema::User - User table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

User table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 insert

Override L<DBIx::Class::Row/insert> to update the email address field.

=cut

sub insert {
    my $self = shift;

    $self->_update_email;
    $self->next::method(@_);
}

=head2 update

Override L<DBIx::Class::Row/update> to update the email address field.

=cut

sub update {
    my $self = shift;

    $self->_update_email;
    $self->next::method(@_);
}

sub _update_email {
    my $self = shift;

    my $domain = $self->result_source->schema->email_domain;
    $self->email($self->username . '@' . $domain);
}

=head2 has_role

Return true if this user has the specified
L<UFL::Workflow::Schema::Role>.

=cut

sub has_role {
    my ($self, $role) = @_;

    $self->throw_exception('You must provide a role')
        unless blessed $role and $role->isa('UFL::Workflow::Schema::Role');

    my @roles = $self->roles;

    return grep { $role->id == $_->id } @roles;
}

=head2 has_group_role

Return true if this user has the specified
L<UFL::Workflow::Schema::Group_Role>.

=cut

sub has_group_role {
    my ($self, $group_role) = @_;

    $self->throw_exception('You must provide a group-role')
        unless blessed $group_role and $group_role->isa('UFL::Workflow::Schema::GroupRole');

    my @group_roles = $self->group_roles;

    return grep {
        $group_role->group_id == $_->group_id
            and $group_role->role_id == $_->role_id
    } @group_roles;
}

=head2 can_decide_on

Return true if this user can decide on the specified
L<UFL::Workflow::Schema::Action>.

=cut

sub can_decide_on {
    my ($self, $action) = @_;

    $self->throw_exception('You must provide an action')
        unless blessed $action and $action->isa('UFL::Workflow::Schema::Action');

    my $has_group_role = 0;
    if (my @groups = $action->groups) {
        my $user_group_roles = $self->user_group_roles->search({
            group_id => { -in => [ map { $_->id } @groups ] },
            role_id  => $action->step->role->id,
        });

        if ($user_group_roles->count > 0) {
            $has_group_role = 1;
        }
    }

    return ($action->status->is_initial and $has_group_role);
}

=head2 can_manage

Return true if this user can manage the specified
L<UFL::Workflow::Schema::Request>.

=cut

sub can_manage {
    my ($self, $request) = @_;

    $self->throw_exception('You must provide a request')
        unless blessed $request and $request->isa('UFL::Workflow::Schema::Request');

    # Allow users with current (pending) step's group-role or a past group role
    my $has_group_role = 0;

    my $possible_actors = $request->possible_actors;
    $has_group_role = 1 if $possible_actors->count({ user_id => $self->id }) > 0;
    $has_group_role = 1 if $self->_has_past_group_role($request);

    return ($request->is_open and ($self->id == $request->user_id || $has_group_role));
}

=head2 can_view

Return true if this user can view the specified
L<UFL::Workflow::Schema::Request>.

=cut

sub can_view {
    my ($self, $request) = @_;

    $self->throw_exception('You must provide a request')
        unless blessed $request and $request->isa('UFL::Workflow::Schema::Request');

    # Always allow access if the process is unrestricted
    return 1 unless $request->process->restricted;

    # Always allow the submitter
    return 1 if $self->id == $request->user_id;

    # Allow users with current (pending) step's group-role
    my $possible_actors = $request->possible_actors;
    return 1 if $possible_actors->count({ user_id => $self->id }) > 0;

    return 1 if $self->_has_past_group_role($request);
    return 1 if $self->_has_future_role($request);

    return 0;
}

sub _has_past_group_role {
    my ($self, $request) = @_;

    my $has_past_group_role = 0;

    my $action = $request->current_action;
    while ($action = $action->prev_action) {
        my $user_group_roles = $action->user_group_roles->search({
            user_id => $self->id,
            role_id => $action->step->role->id,
        });

        if ($user_group_roles->count > 0) {
            $has_past_group_role = 1;
            last;
        }
    }

    return $has_past_group_role;
}

sub _has_future_role {
    my ($self, $request) = @_;

    my $step = $request->current_step;
    my @future_roles;
    while ($step = $step->next_step) {
        push @future_roles, $step->role;
    }

    my $has_future_role = 0;

    if (@future_roles) {
        my $user_group_roles = $self->user_group_roles->search({
            role_id => { -in => [ map { $_->id } @future_roles ] },
        });

        if ($user_group_roles->count > 0) {
            $has_future_role = 1;
        }
    }

    return $has_future_role;
}

=head2 pending_actions

Return a L<DBIx::Class::ResultSet> containing
L<UFL::Workflow::Schema::Action>s which are pending action from this
user.

=cut

sub pending_actions {
    my ($self) = @_;

    my $pending_actions = $self->result_source->schema->resultset('Action')->search(
        {
            'user_group_role.user_id' => $self->id,
            'step.role_id'            => \q[= user_group_role.role_id],
            'status.is_initial'       => 1,
        },
        {
            join     => [ { action_groups => 'user_group_role' }, 'status', 'step' ],
            distinct => 1,
            order_by => \q[update_time DESC, insert_time DESC],
        },
    );

    return $pending_actions;
}

=head2 recent_requests

Return a L<DBIx::Class::ResultSet> containing the
L<UFL::Workflow::Schema::Request>s entered by this user that have been
updated within the past week.

=cut

sub recent_requests {
    my ($self) = @_;

    my $recent_requests = $self->requests->search({
        update_time => \q[>= CURRENT TIMESTAMP - 7 DAYS],
    });

    return $recent_requests;
}

=head2 group_requests

Return a L<DBIx::Class::ResultSet> containing
L<UFL::Workflow::Schema::Request>s for groups of which this user is a
member.

=cut

sub group_requests {
    my ($self) = @_;

    my @groups = $self->groups;

    my $group_requests;
    if (@groups) {
        $group_requests = $self->result_source->schema->resultset('Request')->search(
            {
                'process.restricted' => 0,
                'submitter.id'       => { '!=' => $self->id },
                -or => [
                    'group.id'              => { -in => [ map { $_->id } @groups ] },
                    'group.parent_group_id' => { -in => [ map { $_->id } @groups ] },
                ],
            },
            {
                join     => [ 'process', { submitter => { user_group_roles => 'group' } } ],
                distinct => 1,
                order_by => \q[update_time DESC, insert_time DESC],
            },
        );
    }

    return $group_requests;
}

=head2 uri_args

Return the list of URI path arguments needed to identify this user.

=cut

sub uri_args {
    my ($self) = @_;

    return [ $self->username ];
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
