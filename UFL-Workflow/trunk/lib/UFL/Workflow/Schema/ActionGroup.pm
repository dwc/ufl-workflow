package UFL::Workflow::Schema::ActionGroup;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('action_groups');
__PACKAGE__->add_columns(
    action_id => {
        data_type => 'integer',
    },
    group_id => {
        data_type => 'integer',
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->set_primary_key(qw/action_id group_id/);

__PACKAGE__->belongs_to(
    action => 'UFL::Workflow::Schema::Action',
    'action_id',
);

__PACKAGE__->belongs_to(
    group => 'UFL::Workflow::Schema::Group',
    'group_id',
);

__PACKAGE__->belongs_to(
    group_role => 'UFL::Workflow::Schema::GroupRole',
    { 'foreign.group_id' => 'self.group_id' },
);

__PACKAGE__->belongs_to(
    user_group_role => 'UFL::Workflow::Schema::UserGroupRole',
    { 'foreign.group_id' => 'self.group_id' },
);

=head1 NAME

UFL::Workflow::Schema::ActionGroup - Action-to-group table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Action-to-group table class for L<UFL::Workflow::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
