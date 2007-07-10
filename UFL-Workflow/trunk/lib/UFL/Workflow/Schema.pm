package UFL::Workflow::Schema;

use strict;
use warnings;
use base qw/DBIx::Class::Schema/;

__PACKAGE__->load_classes;

=head1 NAME

UFL::Workflow::Schema - Database schema for UFL::Workflow

=head1 SYNOPSIS

See L<UFL::Workflow>.

=head1 DESCRIPTION

L<DBIx::Class::Schema> for L<UFL::Workflow>.

=head1 METHODS

=head2 deployment_statements

Generate the schema creation statements via
L<DBIx::Class::Storage::DBI/deployment_statements>.

This handles setting the statement separator for e.g. DB2.

=cut

sub deployment_statements {
    my $self = shift;
    my $separator = delete $_[-1]->{separator};

    my @statements = $self->storage->deployment_statements(@_);
    s/;/$separator/g for @statements;

    return @statements;
}

=head2 grant_statements

Generate the C<GRANT> statements for all tables on this
L<DBIx::Class::Schema>.  This currently includes C<SELECT>, C<INSERT>,
C<UPDATE>, and C<DELETE> permissions.

=cut

sub grant_statements {
    my ($self, $user, $separator) = @_;

    $separator ||= ';';

    my @statements;
    foreach my $source_name ($self->sources) {
        my $source = $self->source($source_name);
        my $table_name = $source->from;

        my $grant = <<"END_OF_SQL";
GRANT SELECT, INSERT, UPDATE, DELETE
ON TABLE $table_name
TO USER $user$separator
END_OF_SQL

        chomp $grant;
        push @statements, $grant;
    }

    return @statements;
}

=head2 trigger_statements

Generate the C<CREATE TRIGGER> statements for all tables on this
L<DBIx::Class::Schema>. This currently supports DB2 only.

=cut

sub trigger_statements {
    my ($self, $separator, $field_name) = @_;

    $separator  ||= ';';
    $field_name ||= 'update_time';

    my @statements;
    foreach my $source_name ($self->sources) {
        my $source = $self->source($source_name);
        my $table_name = $source->from;

        next unless $source->has_column($field_name);

        my $trigger_name = "${table_name}_u";
        if (length $trigger_name > 18) {
            my $new_trigger_name = $trigger_name;
            $new_trigger_name =~ s/([A-Za-z])[A-Za-z]+_/$1_/g;

            warn "Shortening trigger [$trigger_name] to [$new_trigger_name]";
            $trigger_name = $new_trigger_name;
        }

        my $drop = "DROP TRIGGER $trigger_name$separator";
        my $create = <<"END_OF_SQL";
CREATE TRIGGER $trigger_name
NO CASCADE BEFORE UPDATE ON $table_name
REFERENCING NEW AS n
FOR EACH ROW MODE DB2SQL
SET n.$field_name = CURRENT TIMESTAMP$separator
END_OF_SQL

        chomp $create;
        push @statements, $drop, $create;
    }

    # Set up one more trigger to update the request timestamp when the action is updated
    push @statements, "DROP TRIGGER requests_action_u$separator";
    push @statements, <<"END_OF_SQL";
CREATE TRIGGER requests_action_u
AFTER UPDATE ON actions
REFERENCING NEW as n
FOR EACH ROW MODE DB2SQL
BEGIN ATOMIC
  UPDATE requests SET $field_name = CURRENT TIMESTAMP WHERE id = n.request_id;
END$separator
END_OF_SQL

    return @statements;
}

=head2 export_statements

Generate the C<EXPORT> statements for all tables on this
L<DBIx::Class::Schema>. This currently supports DB2 only.

=cut

sub export_statements {
    my ($schema, $separator) = @_;

    $separator ||= ';';

    my @statements;
    foreach my $source_name ($schema->sources) {
        my $source = $schema->source($source_name);
        my $table_name = $source->from;

        my $export = "EXPORT TO $table_name.del OF DEL SELECT * FROM $table_name$separator";
        push @statements, $export;
    }

    return @statements;
}

=head2 import_statements

Generate the C<IMPORT> statements for all tables on this
L<DBIx::Class::Schema>. This currently supports DB2 only.

=cut

sub import_statements {
    my ($schema, $separator) = @_;

    $separator ||= ';';

    my @statements;
    foreach my $source_name ($schema->sources) {
        my $source = $schema->source($source_name);
        my $table_name = $source->from;

        my $import = "IMPORT FROM $table_name.del OF DEL MODIFIED BY DELPRIORITYCHAR USEDEFAULTS REPLACE INTO $table_name$separator";
        push @statements, $import;
    }

    return @statements;
}

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.edu<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
