package UFL::Curriculum::Controller::Authentication;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

=head1 NAME

UFL::Curriculum::Controller::Authentication - Authentication controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<Catalyst> controller component for authentication.

=head1 METHODS

=head2 logout

Logout the current user.

=cut

sub logout : Global {
    my ($self, $c) = @_;

    $c->logout;
    if (my $logout_uri = $c->config->{logout_uri}) {
        $c->res->redirect($logout_uri);
    }
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
