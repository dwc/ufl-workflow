package UFL::Workflow::ResultSet::Action;

use strict;
use warnings;
use base qw/DBIx::Class::ResultSet/;

=head1 NAME

UFL::Workflow::ResultSet::Action - Action resultset class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<DBIx::Class::ResultSet> for L<UFL::Workflow::Schema::Action>.

=head1 METHODS

=head2 current_actions

Return a L<DBIx::Class::ResultSet> of current actions across all
L<UFL::Workflow::Schema::Request>s.

=cut

sub current_actions {
    my ($self) = @_;

    my $current_actions = $self->search({ next_action_id => undef });

    return $current_actions;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
