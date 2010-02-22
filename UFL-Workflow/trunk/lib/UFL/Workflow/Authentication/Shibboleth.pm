package UFL::Workflow::Authentication::Shibboleth;

use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use MRO::Compat;

__PACKAGE__->mk_accessors(qw/source username_field update_fields realm/);

=head1 NAME

UFL::Workflow::Authentication::Shibboleth - Catalyst::Plugin::Authentication credential for UF Shibboleth

=head1 SYNOPSIS

    # In MyApp.pm
    __PACKAGE__->config(
        'Plugin::Authentication' => {
            default_realm => 'myrealm',
            realms => {
                credential => {
                    class => '+UFL::Workflow::Authentication::Shibboleth',
                },
            },
        },
    );

    # In your root controller, to implement automatic login
    sub begin : Private {
        my ($self, $c) = @_;
        unless ($c->user_exists) {
            unless ($c->authenticate()) {
                # Return a 403 Forbidden status
            }
        }
    }

    # Or you can use an ordinary login action
    sub login : Global {
        my ($self, $c) = @_;
        $c->authenticate();
    }

=head1 DESCRIPTION

This module allows you to authenticate users via arbitrary keys in the
environment.  It is similar to
L<Catalyst::Authentication::Credential::Remote>, but does not have any
restriction on which fields can be used to determine the username.

This allows it to be used in conjunction with Shibboleth.

=head1 CONFIGURATION

=head2 class

(Required) Part of the core L<Catalyst::Plugin::Authentication>
module. This must be set to
C<+UFL::Workflow::Authentication::Shibboleth> for this module to be
used.

=head2 source

(Optional) Specifies the environment variable passed from the external
authentication setup that contains the username.

By default, this is set to C<ufid>.

=head2 username_field

(Optional) The key name for C<< $c->authenticate >> that the user's
username is mapped to.

By default, this is set to C<username>.

=head1 METHODS

=head2 new

Instantiate a new object using the configuration hash.

=cut

sub new {
    my ($class, $config, $c, $realm) = @_;

    my $self = $class->next::method;

    $self->source($config->{source} || 'ufid');
    $self->username_field($config->{username_field} || 'username');
    $self->realm($realm);

    return $self;
}

=head2 authenticate

Take the username from the environment and attempt to find a user.

=cut

sub authenticate {
    my ($self, $c, $realm, $authinfo) = @_;

    my $env = $c->engine->env;

    my $source = $self->source;
    my $remote_user = $env->{$source};
    return if not defined $remote_user or $remote_user eq '';

    my $auth_user = $authinfo->{username};
    return if defined $auth_user and $auth_user ne $remote_user;

    $authinfo->{$self->username_field} = $remote_user;
    my $user_obj = $realm->find_user($authinfo, $c);

    return $user_obj;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
