package UFL::Workflow::Plugin::Authentication::Credential::Passthrough;

use strict;
use warnings;
use NEXT;
use Scalar::Util qw(blessed);

=head1 NAME

UFL::Workflow::Plugin::Authentication::Credential::Passthrough - Passthrough authentication for Catalyst

=head1 SYNOPSIS

    use Catalyst qw/
        Authentication
        +UFL::Workflow::Plugin::Authentication::Credential::Passthrough
        Authentication::Store::DBIC
    /;

=head1 DESCRIPTION

Use an existing external authentication mechanism with L<Catalyst>.

=head1 METHODS

=head2 prepare_request

Automatically login the current user.  By default the username is
pulled from the C<REMOTE_USER> key, but you can configure the behavior
by setting C<< $c->config->{authentication}->{passthrough}->{key} >>.

When running under the built-in server or when running tests (i.e.,
when C<HARNESS_ACTIVE> is set), the C<USER> environment variable is
also checked.

=cut

sub prepare_request {
    my $c = shift;

    my $rv = $c->NEXT::prepare_request(@_);

    unless ($c->user_exists) {
        my $key = $c->config->{authentication}->{passthrough}->{key}
            || 'REMOTE_USER';

        my $username = $ENV{$key};
        if (not $username and ($ENV{HARNESS_ACTIVE} or ref($c->engine) =~ /::HTTP\b/)) {
            $username = $ENV{USER};
        }

        $c->login($username);
    }

    return $rv;
}

=head2 login

"Login" the specified user.  No password verification is done; you
must do this externally.

Note that users must still exist in the default store.

=cut

sub login {
    my ($c, $user) = @_;

    $c->log->debug("Can't login a user without a user object or username parameter")
        and return 0 unless $user;

    unless (blessed $user and $user->isa('Catalyst:::Plugin::Authentication::User')) {
        my $user_obj = $c->get_user($user);
        if ($user_obj) {
            $user = $user_obj;
        }
        else {
            $c->log->debug("User '$user' doesn't exist in the default store")
                if $c->debug;
            return 0;
        }
    }

    $c->set_authenticated($user);
    $c->log->debug("Successfully authenticated user '$user'")
        if $c->debug;

    return 1;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
