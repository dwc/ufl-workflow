package UFL::Curriculum::Controller::Requests;

use strict;
use warnings;
use base qw/UFL::Curriculum::BaseController/;

=head1 NAME

UFL::Curriculum::Controller::Requests - Requests controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing requests.

=head1 METHODS

=head2 index

Display a list of the user's current requests.

=cut

sub index : Path Args(0) {
    my ($self, $c) = @_;

    my $requests = $c->user->requests;
    my $processes = $c->model('DBIC::Process')->search(undef, { order_by => 'name' });

    $c->stash(
        requests  => $requests,
        processes => $processes,
        template  => 'requests/index.tt',
    );
}

=head2 request

Fetch the specified request.

=cut

sub request : PathPart('requests') Chained('/') CaptureArgs(1) {
    my ($self, $c, $request_id) = @_;

    my $request = $c->model('DBIC::Request')->find($request_id);
    $c->detach('/default') unless $request;

    $c->stash(request => $request);
}

=head2 view

Display basic information on the stashed request.

=cut

sub view : PathPart('') Chained('request') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'requests/view.tt');
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
