package UFL::Workflow::Controller::Authentication;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->mk_accessors(qw/logout_uri update_user_fields_on_login/);

__PACKAGE__->config(
    update_user_fields_on_login => [],
);

=head1 NAME

UFL::Workflow::Controller::Authentication - Authentication controller component

=head1 SYNOPSIS

See L<Catalyst::Controller>.

=head2 login_via_env

Log the user in based on the environment (via C<REMOTE_USER>).

=cut

sub login_via_env : Private {
    my ($self, $c) = @_;

    # XXX: Catalyst::Plugin::Authentication supports checking active flag
    # XXX: in $c->authenticate, but it conflicts with auto_create_user
    $c->authenticate();
    $c->forward('/forbidden') and return 0
        unless $c->user_exists and $c->user->active;

    # Pass any additional information from the environment
    foreach my $field (@{ $self->update_user_fields_on_login }) {
        $c->user->obj->$field($c->engine->env->{$field});
    }

    # Update the user object to cache the values from the environment
    $c->user->obj->update if $c->user->obj->can('update');

    return 1;
}

=head2 login_via_form

Log the user in via a standard username and password form.

=cut

sub login_via_form : Private {
    my ($self, $c) = @_;

    # Allow access for logged-in users and also to the login form
    if ($c->user_exists or $c->action eq $self->action_for('login')) {
        return 1;
    }

    $c->res->redirect($c->uri_for($self->action_for('login'), { return_to => $c->req->uri }));

    return 0;
}

=head2 login

Public action (C</login>) for L</login_via_form>.

=cut

sub login : Global {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $username = $c->req->param('username');
        my $password = $c->req->param('password');

        if ($username and $password) {
            if (my $return_to = $c->req->param('return_to')) {
                $c->stash(return_to => $return_to);
            }

            $c->detach('redirect') if $c->authenticate({
                username => $username,
                password => $password,
                active   => 1,
            });
        }

        $c->stash(authentication_error => 1) unless $c->user_exists;
    }

    $c->stash(template => 'authentication/login.tt');
}

=head2 redirect

Determine where to send the user after successful login. We default to
the home page but allow specification of a C<return_to> parameter in
case the calling login method knows a better place to send the user.

=cut

sub redirect : Private {
    my ($self, $c) = @_;

    # Determine where to send the user
    my $location = $c->stash->{return_to}
        || $c->uri_for($c->controller('Root')->action_for('index'));

    return $c->res->redirect($location);
}

=head2 logout

Logout the current user.

=cut

sub logout : Global {
    my ($self, $c) = @_;

    $c->logout;

    my $logout_uri = $self->logout_uri
        || $c->uri_for($c->controller('Root')->action_for('index'));
    $c->res->redirect($logout_uri);
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
