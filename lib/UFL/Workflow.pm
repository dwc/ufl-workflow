package UFL::Workflow;

use strict;
use warnings;
use MRO::Compat;
use Catalyst qw/
    ConfigLoader
    Setenv
    Authentication
    Authorization::Roles
    Authorization::ACL
    ErrorCatcher
    FillInForm
    Session
    Session::State::Cookie
    Session::Store::File
    StackTrace
    Static::Simple
    Unicode::Encoding
/;

our $VERSION = '0.43_01';

__PACKAGE__->setup;

# Restrict administrative interface to 'Administrator' role
__PACKAGE__->deny_access_unless(
    "/$_",
    [ qw/Administrator/ ],
) for qw/groups processes roles statuses steps/;

# Restrict user administration to 'Administrator' and 'Help Desk' roles
__PACKAGE__->deny_access_unless(
    "/users",
    sub { shift->check_any_user_role('Administrator', 'Help Desk') },
);

# Allow any logged-in user to add requests
__PACKAGE__->allow_access_if(
    "/processes/$_",
    sub { $_[0]->user_exists },
) for qw/process add_request/;

# Allow any logged-in user to view their user page and toggle email preference
__PACKAGE__->allow_access_if(
    "/users/$_",
    sub { $_[0]->user_exists },
) for qw/user view toggle_email/;

# Allow users with 'Help Desk' role to view administrative information
__PACKAGE__->allow_access_if(
    "/processes/$_",
    [ 'Help Desk' ],
) for qw/index view requests/;

__PACKAGE__->allow_access_if(
    "/groups/$_",
    [ 'Help Desk' ],
) for qw/index group view/;

__PACKAGE__->allow_access_if(
    "/roles/$_",
    [ 'Help Desk' ],
) for qw/role view/;

__PACKAGE__->allow_access_if(
    "/statuses/$_",
    [ 'Help Desk' ],
) for qw/index status view/;

__PACKAGE__->allow_access_if(
    "/steps/$_",
    [ 'Help Desk' ],
) for qw/step view/;

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

=head1 METHODS

=head2 finalize_error

Output a more friendly error page. This is based loosely on
L<Catalyst::Plugin::CustomErrorMessage>.

=cut

sub finalize_error {
    my $c = shift;

    # Allow ErrorCatcher to run
    $c->next::method(@_);

    # Allow StackTrace to take over in debug mode
    return if $c->debug;

    # Forward to the more friendly error page
    eval {
        $c->res->body($c->view('HTML')->render($c, 'error.tt'));
    };
    if ($@) {
        # Handle view-level errors by logging them
        $c->log->error($@);
    }
}

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
