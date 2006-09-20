package UFL::Curriculum::Schema::ResultSource::Step;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Schema::Component::StandardColumns Core/);

__PACKAGE__->table('steps');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    process_id => {
        data_type => 'integer',
    },
    role_id => {
        data_type => 'varchar',
        size      => '32',
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    process => 'UFL::Curriculum::Schema::ResultSource::Process',
    'process_id',
);

__PACKAGE__->belongs_to(
    role => 'UFL::Curriculum::Schema::ResultSource::Role',
    'role_id',
);

=head1 NAME

UFL::Curriculum::Schema::ResultSource::Step - Step table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Step table class for L<UFL::Curriculum::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
