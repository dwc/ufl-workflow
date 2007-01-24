package UFL::Workflow;

use strict;
use warnings;
use Catalyst qw/
    ConfigLoader
    Setenv
    Authentication
    +UFL::Workflow::Plugin::Authentication::Credential::Passthrough
    Authentication::Store::DBIC
    Authorization::Roles
    Authorization::ACL
    FillInForm
    StackTrace
    Static::Simple
    Unicode::Encoding
/;

our $VERSION = '0.08_01';

__PACKAGE__->setup;

__PACKAGE__->deny_access_unless(
    "/$_",
    [ qw/Administrator/ ],
) for qw/groups processes roles statuses steps users/;

__PACKAGE__->allow_access_if(
    "/processes/$_",
    sub { $_[0]->user_exists },
) for qw/process add_request/;

=head1 NAME

UFL::Workflow - Workflow tracking for the University of Florida

=head1 SYNOPSIS

    script/ufl_workflow_server.pl

=head1 DESCRIPTION

This application tracks documents and requests through various
processes.

For example, professors at the University of Florida identify new or
modified undergraduate and graduate courses for the student body.
This application allows professors to submit course requests.

=head1 SEE ALSO

=over 4

=item * L<UFL::Workflow::Controller::Root>

=item * L<Catalyst>

=back

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
