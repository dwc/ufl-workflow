#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use UFL::Workflow::Schema;

my $type = $ARGV[0] || 'DB2';

my $schema = UFL::Workflow::Schema->connect;
my @statements = $schema->storage->deployment_statements($schema, $type, undef, undef, { add_drop_table => 1 });

# Add update triggers here since they can't be declared on the schema
if ($type eq 'DB2') {
    my $field_name = 'update_time';

    foreach my $source_name ($schema->sources) {
        my $source = $schema->source($source_name);
        next unless $source->has_column($field_name);

        my $table_name = $source->from;
        my $trigger_name = "${table_name}_u";
        if (length $trigger_name > 18) {
            my $new_trigger_name = $trigger_name;
            $new_trigger_name =~ s/([A-Za-z])[A-Za-z]+_/$1_/g;

            warn "Shortening trigger [$trigger_name] to [$new_trigger_name]";
            $trigger_name = $new_trigger_name;
        }

        my $l = length($trigger_name);

        my $drop = "DROP TRIGGER $trigger_name;";
        my $create = <<"END_OF_SQL";
CREATE TRIGGER $trigger_name
NO CASCADE BEFORE UPDATE ON $table_name
REFERENCING NEW AS n
FOR EACH ROW MODE DB2SQL
SET n.$field_name = CURRENT TIMESTAMP;
END_OF_SQL

        chomp $create;
        push @statements, $drop, $create;
    }
}

print "--\n";
print "-- Generated by $0 on " . scalar(localtime) . "\n";
print "--\n";
print "\n";
print join "\n\n", @statements;
print "\n";
