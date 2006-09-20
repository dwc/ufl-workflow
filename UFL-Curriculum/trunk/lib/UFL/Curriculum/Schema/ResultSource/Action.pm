package UFL::Curriculum::Schema::ResultSource::Action;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Schema::Component::StandardColumns Core/);

__PACKAGE__->table('actions');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    request_id => {
        data_type => 'integer',
    },
    step_id => {
        data_type => 'integer',
    },
    user_id => {
        data_type => 'integer',
    },
    status => {
        data_type => 'varchar',
        size      => 1,
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    request => 'UFL::Curriculum::Schema::ResultSource::Request',
    'request_id',
);

__PACKAGE__->belongs_to(
    step => 'UFL::Curriculum::Schema::ResultSource::Step',
    'step_id',
);

__PACKAGE__->belongs_to(
    actor => 'UFL::Curriculum::Schema::ResultSource::User',
    'user_id',
);

=head1 NAME

UFL::Curriculum::Schema::ResultSource::Action - Action table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Action table class for L<UFL::Curriculum::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
