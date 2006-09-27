package UFL::Curriculum::Controller::Processes;

use strict;
use warnings;
use base qw/UFL::Curriculum::BaseController/;

=head1 NAME

UFL::Curriculum::Controller::Processes - Processes controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

L<Catalyst> controller component for managing processes.

=head1 METHODS

=head2 index 

Display a list of current processes.

=cut

sub index : Path Args(0) {
    my ($self, $c) = @_;

    my $processes = $c->model('DBIC::Process')->search(undef, { order_by => 'name' });

    $c->stash(
        processes => $processes,
        template  => 'processes/index.tt',
    );
}

=head2 add

Add a new process.

=cut

sub add : Local {
    my ($self, $c) = @_;

    if ($c->req->method eq 'POST') {
        my $result = $self->validate_form($c);
        if ($result->success) {
            my $process = $c->user->processes->find_or_create({
                name => $result->valid('name'),
            });

            return $c->res->redirect($c->uri_for($self->action_for('view'), [ $process->uri_args ]));
        }
    }

    $c->stash(template => 'processes/add.tt');
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
