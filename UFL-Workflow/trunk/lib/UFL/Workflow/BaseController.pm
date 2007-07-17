package UFL::Workflow::BaseController;

use strict;
use warnings;
use base qw/Catalyst::Controller/;
use Carp qw/croak/;
use FormValidator::Simple;
use FormValidator::Simple::ProfileManager::YAML;
use Module::Find ();

__PACKAGE__->mk_accessors(qw/profiles_file messages_file datetime_class/);

# For FormValidator::Simple
our $DEFAULT_DATETIME_CLASS = 'DateTime';

=head1 NAME

UFL::Workflow::BaseController - Base controller component

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

Base L<Catalyst> controller component, containing common form
validation code.

=head1 METHODS

=head2 new

Create a new controller, also setting up various data for validation.

=cut

sub new {
    my $self = shift->SUPER::new(@_);
    my ($c, $config) = @_;

    my $path = $c->path_to('root', $self->path_prefix($c));
    if (-d $path) {
        $self->profiles_file($path->file('profiles.yml'))
            unless $self->profiles_file;
        $self->messages_file($path->file('messages.yml'))
            unless $self->messages_file;
    }

    $self->datetime_class($DEFAULT_DATETIME_CLASS)
        unless $self->datetime_class;

    return $self;
}

=head2 validate_form

Validate the current form (as determined from C<< $c->action->name >>)
and return the result (a L<FormValidator::Simple::Results> object).

Also, stash any error messages under the C<form_errors> key.

=cut

sub validate_form {
    my ($self, $c) = @_;

    my $profiles_file = $self->profiles_file;
    croak 'No form profiles were found' unless -e $profiles_file;

    my $messages_file = $self->messages_file;
    croak 'No form messages were found' unless -e $messages_file;

    # XXX: Would love to instantiate these in new, but FVS holds some class data
    my $manager   = FormValidator::Simple::ProfileManager::YAML->new($profiles_file);
    my $validator = FormValidator::Simple->new;
    $validator->load_plugin($_)
        for Module::Find::findallmod('UFL::Workflow::Plugin::FormValidator');
    $validator->set_option(datetime_class => $self->datetime_class);
    $validator->set_messages($messages_file);

    my $name    = $c->action->name;
    my $profile = $manager->get_profile($name);
    croak "No form profile found for action $name" unless $profile;

    my $result = $validator->check($c->req, $profile);

    $c->stash(
        form_errors => $result->messages($name),
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
