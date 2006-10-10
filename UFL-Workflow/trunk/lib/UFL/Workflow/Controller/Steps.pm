package UFL::Workflow::Controller::Steps;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

=head1 NAME

UFL::Workflow::Controller::Steps - Steps controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing steps.

=head1 METHODS

=head2 step

Fetch the specified step.

=cut

sub step : PathPart('steps') Chained('/') CaptureArgs(1) {
    my ($self, $c, $step_id) = @_;

    my $step = $c->model('DBIC::Step')->find($step_id);
    $c->detach('/default') unless $step;

    $c->stash(step => $step);
}

=head2 view

Display basic information on the stashed step.

=cut

sub view : PathPart('') Chained('step') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'steps/view.tt');
}

=head2 edit

Edit the stashed step.

=cut

sub edit : PathPart Chained('step') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $step = $c->stash->{step};

            my $values = $result->valid;
            foreach my $key (keys %$values) {
                $step->$key($values->{$key}) if $step->can($key);
            }

            # TODO: Unique check
            $step->update;

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $step->uri_args ]));
        }
    }

    $c->stash(template => 'steps/edit.tt');
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
