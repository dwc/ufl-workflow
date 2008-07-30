package UFL::Workflow::Plugin::FormValidator::DateAllowingBlank;

use strict;
use warnings;
use FormValidator::Simple::Constants;

=head1 NAME

UFL::Workflow::Plugin::FormValidator::DateAllowingBlank - A FormValidator::Simple plugin for allowing blank DATE fields

=head1 SYNOPSIS

    FormValidator::Simple->load_plugin('UFL::Workflow::Plugin::FormValidator::DateAllowingBlank');
    my $v = FormValidator::Simple->new;
    $v->check($query => [
        { date => [qw/year month day/] } => [ qw/DATE_ALLOWING_BLANK/ ],
    ]);

=head1 DESCRIPTION

This is a simple wrapper around the C<DATE> constraint in
L<FormValidator::Simple> which allows blank fields. It can be used in
situations where the date fields of your form are optional but you
still want to validate them as dates.

=head1 METHODS

=head2 DATE_ALLOWING_BLANK

Allow blank C<DATE> fields to pass validation by doing a check for
blank values.

=cut

sub DATE_ALLOWING_BLANK {
    my ($self, $params, $args) = @_;

    return TRUE if grep { not defined $_ or $_ eq '' } @$params;
    return $self->DATE($params, $args);
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>danieltwc@cpan.orgE<gt>

=head1 ACKNOWLEDGMENTS

Lyo Kato E<lt>lyo.kato@gmail.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
