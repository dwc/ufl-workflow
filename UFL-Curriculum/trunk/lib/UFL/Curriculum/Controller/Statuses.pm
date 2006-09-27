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

        my $continues_request = ($result->valid('action') eq 'continue');
        my $finishes_request  = ($result->valid('action') eq 'finish');
        $finishes_request = 0 if $continues_request;

        if ($result->success) {
            my $status = $c->model('DBIC::Status')->find_or_create({
                name              => $result->valid('name'),
                continues_request => $continues_request,
                finishes_request  => $finishes_request,
            });

            return $c->res->redirect($c->uri_for($self->action_for('index')));
        }
    }

    $c->stash(template => 'statuses/add.tt');
}

=head2 status

Fetch the specified status.

=cut

sub status : PathPart('statuses') Chained('/') CaptureArgs(1) {
    my ($self, $c, $status_id) = @_;

    my $status = $c->model('DBIC::Status')->find($status_id);
    $c->detach('/default') unless $status;

    $c->stash(status => $status);
}

=head2 view

Display basic information on the stashed status.

=cut

sub view : PathPart('') Chained('status') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'statuses/view.tt');
}

=head2 edit

Edit the stashed status.

=cut

sub edit : PathPart Chained('status') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $status = $c->stash->{status};

            my $values = $result->valid;
            foreach my $key (keys %$values) {
                $status->$key($values->{$key}) if $status->can($key);
            }

            # TODO: Unique check
            $status->update;

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $status->uri_args ]));
        }
    }

    $c->stash(template => 'statuses/edit.tt');
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
