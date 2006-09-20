package UFL::Curriculum::Schema::Comment;

use strict;
use warnings;
use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/+UFL::Curriculum::Component::StandardColumns Core/);

__PACKAGE__->table('comments');
__PACKAGE__->add_standard_primary_key;
__PACKAGE__->add_columns(
    action_id => {
        data_type => 'integer',
    },
    body => {
        data_type => 'text',
    },
);
__PACKAGE__->add_standard_columns;

__PACKAGE__->belongs_to(
    action => 'UFL::Curriculum::Schema::Action',
    'action_id',
);

=head1 NAME

UFL::Curriculum::Schema::Comment - Comment table class

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Comment table class for L<UFL::Curriculum::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
