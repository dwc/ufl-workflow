package UFL::Curriculum::Controller::Statuses;

use strict;
use warnings;
use base qw/UFL::Curriculum::BaseController/;

=head1 NAME

UFL::Curriculum::Controller::Statuses - Statuses controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing statuses.

=head1 METHODS

=head2 index 

Display a list of current statuses.

=cut

sub index : Path Args(0) {
    my ($self, $c) = @_;

    my $statuses = $c->model('DBIC::Status')->search(undef, { order_by => 'name' });

    $c->stash(
        statuses => $statuses,
        template => 'statuses/index.tt',
    );
}

=head2 add

Add a new status.

=cut

sub add : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        $result->set_invalid(action => 'DEFAULT')
            if $result->valid('continues_request') and $result->valid('finishes_request');

        if ($result->success) {
            my $status = $c->model('DBIC::Status')->find_or_create({
                name              => $result->valid('name'),
                continues_request => $result->valid('continues_request'),
                finishes_request  => $result->valid('finishes_request'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('index')));
        }
    }

    $c->stash(template => 'statuses/add.tt');
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
