package UFL::Workflow::Controller::Fields;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

=head1 NAME

UFL::Workflow::Controller::Fields - Fields controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing fields.

=head1 METHODS

=head2 field

Fetch the specified field.

=cut

sub field : PathPart('fields') Chained('/') CaptureArgs(1) {
    my ($self, $c, $field_id) = @_;

    my $field = $c->model('DBIC::Field')->find($field_id);
    $c->detach('/default') unless $field;

    $c->stash(field => $field);
}

=head2 view

Display basic information on the stashed field.

=cut

sub view : PathPart('') Chained('field') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'fields/view.tt');
}

=head2 edit

Edit the stashed field.

=cut

sub edit : PathPart Chained('field') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $field = $c->stash->{field};
            $field->update({
                name        => $result->valid('name'),
		description => $result->valid('description'),
		type        => $result->valid('type'),
		min_length  => $result->valid('min_length'),
		max_length  => $result->valid('max_length'),
		optional    => $result->valid('optional')
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $field->uri_args));
        }
    }

    $c->stash(template => 'fields/edit.tt');
}

=head1 AUTHOR

Chetan Murthy E<lt>chetanmurthy@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
