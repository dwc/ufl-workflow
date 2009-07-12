package UFL::Workflow::Model::DBIC;

use strict;
use warnings;
use base qw/Catalyst::Model::DBIC::Schema/;

=head1 NAME

UFL::Workflow::Model::DBIC - DBIC Catalyst model component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<DBIx::Class> L<Catalyst> model component.

=head1 METHODS

=head2 new

Set the domain for email addresses as configured on the application.

=cut

sub new {
    my $self = shift->next::method(@_);
    my $config = $_[0];

    my $domain = $config->{email_domain};
    die 'No email domain configured' unless $domain;

    $self->schema->email_domain($domain);

    return $self;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
