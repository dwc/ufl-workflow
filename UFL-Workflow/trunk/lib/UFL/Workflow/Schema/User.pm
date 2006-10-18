package UFL::Workflow::Schema::User;

use strict;
use warnings;
use base qw/DBIx::Class/;
use Carp qw/croak/;
use Scalar::Util qw/blessed/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('users');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    username => {
        data_type => 'varchar',
        size      => 16,
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

=head1 NAME

UFL::Workflow::Schema::User - User table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

User table class for L<UFL::Workflow::Schema>.

=head1 METHODS

=head2 has_role

Return true if this user has the specified
L<UFL::Workflow::Schema::Role>.

=cut

sub has_role {
    my ($self, $role) = @_;

    croak 'You must provide a role'
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

    croak 'You must provide a group-role'
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

    croak 'You must provide an action'
        unless blessed $action and $action->isa('UFL::Workflow::Schema::Action');

    return ($action->status->is_initial and $self->has_role($action->step->role));
}

=head2 uri_args

Return the list of URI path arguments needed to identify this user.

=cut

sub uri_args {
    my ($self) = @_;

    return $self->username;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;