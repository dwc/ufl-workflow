package UFL::Curriculum::Schema::ResultSource::UserRole;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Schema::Component::StandardColumns Core/);

__PACKAGE__->table('user_roles');
__PACKAGE__->add_columns(
    user_id => {
        data_type => 'integer',
    },
    role_id => {
        data_type => 'integer',
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->set_primary_key(qw/user_id role_id/);

__PACKAGE__->belongs_to(
    # 'user' is reserved by SQL-92
    actor => 'UFL::Curriculum::Schema::ResultSource::User',
    'user_id',
);

__PACKAGE__->belongs_to(
    role => 'UFL::Curriculum::Schema::ResultSource::Role',
    'role_id',
);

=head1 NAME

UFL::Curriculum::Schema::ResultSource::UserRole - User-to-role table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

User-to-role table class for L<UFL::Curriculum::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
