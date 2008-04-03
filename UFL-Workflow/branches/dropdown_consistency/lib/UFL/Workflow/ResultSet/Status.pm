package UFL::Workflow::ResultSet::Status;

use strict;
use warnings;
use base qw/DBIx::Class::ResultSet/;

=head1 NAME

UFL::Workflow::ResultSet::Status - Status resultset class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<DBIx::Class::ResultSet> for L<UFL::Workflow::Schema::Status>.

=head1 METHODS

=head2 initial_status

Return the initial status for L<UFL::Workflow::Schema::Request>s.

=cut

sub initial_status {
    my ($self) = @_;

    my $initial_status = $self->search({ is_initial => 1 })->first;
    $self->throw_exception('Could not find initial status')
        unless $initial_status;

    return $initial_status;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
