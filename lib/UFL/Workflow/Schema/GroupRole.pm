package UFL::Workflow::Schema::GroupRole;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('group_roles');
__PACKAGE__->add_columns(
    group_id => {
        data_type => 'integer',
    },
    role_id => {
        data_type => 'integer',
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->set_primary_key(qw/group_id role_id/);

__PACKAGE__->belongs_to(
    group => 'UFL::Workflow::Schema::Group',
    'group_id',
);

__PACKAGE__->belongs_to(
    role => 'UFL::Workflow::Schema::Role',
    'role_id',
);

__PACKAGE__->has_many(
    user_group_roles => 'UFL::Workflow::Schema::UserGroupRole',
    {
        'foreign.group_id' => 'self.group_id',
        'foreign.role_id'  => 'self.role_id',
    },
    { cascade_delete => 0, cascade_copy => 0 },
);

__PACKAGE__->many_to_many('users', 'user_group_roles', 'actor');

=head1 NAME

UFL::Workflow::Schema::GroupRole - Group-to-role table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Group-to-role table class for L<UFL::Workflow::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
