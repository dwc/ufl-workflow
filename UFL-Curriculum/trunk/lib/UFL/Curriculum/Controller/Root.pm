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

=head2 default

Handle any actions which did not match, i.e. 404 errors.

=cut

sub default : Private {
    my ($self, $c) = @_;

    $c->res->status(404);
    $c->stash(template => '404.tt');
}

=head2 index

Display the home page.

=cut

sub index : Path Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'index.tt');
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
