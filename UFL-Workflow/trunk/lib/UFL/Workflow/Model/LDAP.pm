package UFL::Workflow::Model::LDAP;

use base qw/Catalyst::Model::LDAP/;
use Class::C3;

__PACKAGE__->config(
    host => 'ldap.ufl.edu',
    base => 'ou=People,dc=ufl,dc=edu',
);

=head1 NAME

UFL::Workflow::Model::LDAP - LDAP Catalyst model component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst::Model::LDAP> L<Catalyst> model component.

=head1 METHODS

=head2 none

=cut

1;
