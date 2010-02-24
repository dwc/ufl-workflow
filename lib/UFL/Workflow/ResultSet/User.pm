package UFL::Workflow::ResultSet::User;

use strict;
use warnings;
use base qw/DBIx::Class::ResultSet/;

=head1 NAME

UFL::Workflow::ResultSet::User - User resultset class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<DBIx::Class::ResultSet> for L<UFL::Workflow::Schema::User>.

=head1 METHODS

=head2 auto_create

Automatically create a user account with the specified username.

=cut

sub auto_create {
    my ($self, $authinfo) = @_;

    my $user = $self->find_or_create({
        username => $authinfo->{username},
    });

    return $user;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
