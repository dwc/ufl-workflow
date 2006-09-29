package UFL::Curriculum::Schema::Action;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

__PACKAGE__->table('actions');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    request_id => {
        data_type => 'integer',
    },
    step_id => {
        data_type => 'integer',
    },
    status_id => {
        data_type => 'integer',
    },
    user_id => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    comment => {
        data_type   => 'varchar',
        size        => 1024,
        is_nullable => 1,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    request => 'UFL::Curriculum::Schema::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    step => 'UFL::Curriculum::Schema::Step',
    'step_id',
);

__PACKAGE__->belongs_to(
    status => 'UFL::Curriculum::Schema::Status',
    'status_id',
);

__PACKAGE__->belongs_to(
    actor => 'UFL::Curriculum::Schema::User',
    'user_id',
);

=head1 NAME

UFL::Curriculum::Schema::Action - Action table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Action table class for L<UFL::Curriculum::Schema>.

=head1 METHODS

=head2 uri_args

Return the list of URI path arguments needed to identify this action.

=cut

sub uri_args {
    my ($self) = @_;

    return $self->id;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
