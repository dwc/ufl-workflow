package UFL::Curriculum::BaseController;

use strict;
use warnings;
use base qw/Catalyst::Controller Class::Accessor::Fast/;
use Carp qw/croak/;
use FormValidator::Simple;
use FormValidator::Simple::ProfileManager::YAML;

__PACKAGE__->mk_accessors(qw/_path _manager/);

=head1 NAME

UFL::Curriculum::BaseController - Base controller component

=head1 SYNOPSIS

See L<UFL::Curriculum>.

=head1 DESCRIPTION

Base L<Catalyst> controller component, containing common form
validation code.

=head1 METHODS

=head2 new

Create a new controller, also instantiating the associated form
validation stuff.

=cut

sub new {
    my $self = shift->SUPER::new(@_);
    my $c = $_[0];

    my $path = $c->path_to('root', $self->path_prefix($c));
    if (-d $path) {
        $self->_path($path);

        if (-e (my $profiles_file = $self->profiles_file($path))) {
            my $manager = FormValidator::Simple::ProfileManager::YAML->new($profiles_file);
            $self->_manager($manager);
        }
    }

    return $self;
}

=head2 profiles_file

Return a L<Path::Class> object referring to the form validation
profile definition file for this controller.

=cut

sub profiles_file {
    my ($self) = @_;

    my $filename = $self->config->{profiles_file} || 'profiles.yml';

    return $self->_path->file($filename);
}

=head2 messages_file

Return a L<Path::Class> object referring to the form validation
messages definition file for this controller.

=cut

sub messages_file {
    my ($self) = @_;

    my $filename = $self->config->{messages_file} || 'messages.yml';

    return $self->_path->file($filename);
}

=head2 validate_form

Validate the current form (as determined from C<< $c->action->name >>)
and return the result (a L<FormValidator::Simple::Results> object).

Also, stash any error messages under the C<form_errors> key.

=cut

sub validate_form {
    my ($self, $c) = @_;

    croak 'No form profiles were found' unless $self->_manager;

    my $messages_file = $self->messages_file;
    croak 'No form messages were found' unless -e $messages_file;

    # XXX: Would love to instantiate this in new, but FVS holds some class data
    my $validator = FormValidator::Simple->new;
    $validator->set_messages($messages_file);

    my $profile = $self->_manager->get_profile($c->action->name);
    my $result  = $validator->check($c->req, $profile);

    $c->stash(
        form_errors => $result->messages($c->action->name),
        fillform    => 1,
    );

    return $result;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
