package UFL::Workflow::Controller::Roles;

use strict;
use warnings;
use base qw/UFL::Workflow::BaseController/;

=head1 NAME

UFL::Workflow::Controller::Roles - Roles controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing roles.

=head1 METHODS

=head2 role

Fetch the specified role.

=cut

sub role : PathPart('roles') Chained('/') CaptureArgs(1) {
    my ($self, $c, $role_id) = @_;

    my $role = $c->model('DBIC::Role')->find($role_id);
    $c->detach('/default') unless $role;

    $c->stash(role => $role);
}

=head2 view

Display basic information on the stashed role.

=cut

sub view : PathPart('') Chained('role') Args(0) {
    my ($self, $c) = @_;

    $c->stash(template => 'roles/view.tt');
}

=head2 edit

Edit the stashed role.

=cut

sub edit : PathPart Chained('role') Args(0) {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $role = $c->stash->{role};
            $role->update({
                name => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), $role->uri_args));
        }
    }

    $c->stash(template => 'roles/edit.tt');
}

=head2 list_roles

List all available roles via L<JSON>.

=cut

sub list_roles : Local Args(0) {
    my ($self, $c) = @_;

    my $query = lc($c->request->parameters->{'q'});
    my $roles = $c->model('DBIC::Role')->search({ "LOWER(name)" => { 'like', '%' . $query . '%' } });
    $c->stash(roles => [ map { $_->to_json } $roles->all ]);

    my $view = $c->view('JSON');
    $view->expose_stash([ qw/roles/ ]);
    $c->forward($view);
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
