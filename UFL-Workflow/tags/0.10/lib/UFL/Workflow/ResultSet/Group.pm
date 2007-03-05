package UFL::Workflow::ResultSet::Group;

use strict;
use warnings;
use base qw/DBIx::Class::ResultSet/;

=head1 NAME

UFL::Workflow::ResultSet::Group - Group resultset class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<DBIx::Class::ResultSet> for L<UFL::Workflow::Schema::Group>.

=head1 METHODS

=head2 root_groups

Return a L<DBIx::Class::ResultSet> containing the list of top-level
groups.

=cut

sub root_groups {
    my ($self, $attrs) = @_;

    $attrs->{prefetch} ||= 'child_groups';
    $attrs->{order_by} ||= 'me.name';

    my $rs = $self->search(
        { 'me.parent_group_id' => undef },
        $attrs,
    );

    return $rs;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
