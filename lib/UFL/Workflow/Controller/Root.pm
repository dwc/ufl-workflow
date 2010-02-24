package UFL::Workflow::Controller::Root;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->mk_accessors(qw/authentication_controller authentication_action/);

__PACKAGE__->config(
    namespace                 => '',
    authentication_controller => 'Authentication',
    authentication_action     => 'login_via_form',
);

=head1 NAME

UFL::Workflow::Controller::Root - Root controller

=head1 DESCRIPTION

Root L<Catalyst> controller for L<UFL::Workflow>.

=head1 METHODS

=head2 auto

Require authentication for all pages. The method used for
authentication is flexible, using L<Catalyst::Plugin::Authentication>
and two configuration values.

By default, authentication happens via a standard form, displayed via
L<UFL::Workflow::Controller::Authentication/login_via_form>.

This is configured using the following keys:

    authentication_controller
    authentication_action

You can set the C<authentication_controller> key to any other controller
in your application (i.e. those accessible using C<< $c->controller >>).

Additionally, you can set the C<authentication_action> key to another action
on that L<Catalyst::Controller>. For example,
L<UFL::Workflow::Controller::Authentication> contains a C<login_via_env>
action, which uses the C<REMOTE_USER> environment variable instead of a
basic form.

Finally, you can configure all of this from your local configuration file:

    Controller::Root:
      authentication_action: login_via_env

=cut

sub auto : Private {
    my ($self, $c) = @_;

    my $controller = $self->authentication_controller;
    my $action = $self->authentication_action;

    return $c->forward($c->controller($controller)->action_for($action));
}

=head2 default

Handle any actions which did not match, i.e. 404 errors.

=cut

sub default : Private {
    my ($self, $c) = @_;

    $c->res->status(404);
    $c->stash(template => 'not_found.tt');
}

=head2 index

Display the home page.

=cut

sub index : Path('') Args(0) {
    my ($self, $c) = @_;

    my $requests  = $c->user->recent_requests;
    my $processes = $c->model('DBIC::Process')->search({ enabled => 1 });

    $c->stash(
        requests  => $requests,
        processes => $processes,
        template  => 'index.tt',
    );
}

=head2 faq

Display the FAQ page.

=cut

sub faq : Path('faq') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'faq.tt');
}

=head2 unauthorized

Display a page stating the user is not logged in.

=cut

sub unauthorized : Private {
    my ($self, $c) = @_;

    $c->res->status(401);
    $c->stash(template => 'unauthorized.tt');
}

=head2 forbidden

Display a message stating that the user is not authorized to view the
requested resource.

=cut

sub forbidden : Private {
    my ($self, $c) = @_;

    $c->res->status(403);
    $c->stash(template => 'forbidden.tt');
}

=head2 access_denied

Callback for L<Catalyst::Plugin::Authorization::ACL>.

=cut

sub access_denied : Private {
    my ($self, $c) = @_;

    $c->forward('forbidden');
}

=head2 render

Attempt to render a view, if needed.

=cut

sub render : ActionClass('RenderView') {
    my ($self, $c) = @_;

    if (@{ $c->error }) {
        $c->res->status(500);

        # Override the ugly Catalyst debug screen
        unless ($c->debug) {
            $c->log->error($_) for @{ $c->error };

            $c->stash(
                errors   => $c->error,
                template => 'error.tt',
            );
            $c->clear_errors;
        }
    }
}

=head2 end

Render a view and finish up before sending the response.

=cut

sub end : Private {
    my ($self, $c) = @_;

    # If we're using the stub email sender, flush any messages to the console
    if ($c->view('Email')->mailer->mailer eq 'Test') {
        require Email::Send::Test;
        $c->log->_dump(Email::Send::Test->emails);
        Email::Send::Test->clear;
    }

    $c->forward('render');
    $c->fillform if $c->stash->{fillform};
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
