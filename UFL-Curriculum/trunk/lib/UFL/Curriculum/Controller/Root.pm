package UFL::Curriculum::Controller::Root;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config->{namespace} = '';

=head1 NAME

UFL::Curriculum::Controller::Root - Root controller

=head1 DESCRIPTION

Root L<Catalyst> controller for L<UFL::Curriculum>.

=head1 METHODS

=head2 auto

Require authentication for all pages.

=cut

sub auto : Private {
    my ($self, $c) = @_;

    $c->forward('unauthorized') and return 0
        unless $c->user_exists;

    return 1;
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

sub index : Path Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'index.tt');
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

=head2 end

Attempt to render a view, if needed.

=cut 

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;

    if (@{ $c->error }) {
        $c->res->status(500);

        # Override the ugly Catalyst debug screen
        unless ($c->debug) {
            $c->log->error($_) for @{ $c->error };

            $c->stash->{errors} = $c->error;
            $c->error(0);

            $c->stash->{template} = 'error.tt';
        }
    }
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
