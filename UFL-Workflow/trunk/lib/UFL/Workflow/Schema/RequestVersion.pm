package UFL::Workflow::Schema::RequestVersion;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Workflow::Component::StandardColumns Core/);

__PACKAGE__->table('request_versions');
__PACKAGE__->add_columns(
    request_id => {
        data_type         => 'integer',
    },
    num => {
        data_type         => 'integer',
    },
    user_id => {
        data_type         => 'integer',
    },
    title => {
        data_type         => 'varchar',
        size              => 64,
    },
    description => {
        data_type         => 'varchar',
        size              => 8192,
    },
);

__PACKAGE__->set_primary_key(qw/request_id num/);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    request => 'UFL::Workflow::Schema::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    submitter => 'UFL::Workflow::Schema::User',
    'user_id',
);

=head1 NAME

UFL::Workflow::Schema::RequestVersion - Request version table class

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Request version table class for L<UFL::Workflow::Schema>.


=head2 uri_args

Return the L<UFL::Workflow::Schema::Step> in the
L<UFL::Workflow::Schema::Process> associated with the first
L<UFL::Workflow::Schema::Action> on this request.


Return the list of URI path arguments needed to identify the L<UFL::Workflow::Schema::RequestVersion> of the L<UFL::Workflow::Schema::Request>.

=cut

sub uri_args {
    my ($self) = @_;

    return [ $self->request_id, $self->num ];
}

=head1 AUTHOR

Joey Spooner<lt>spooner@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
