#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";
use UFL::Curriculum::Schema;

my $schema = UFL::Curriculum::Schema->connect;

my @statements = $schema->storage->deployment_statements($schema, $ARGV[0] || 'DB2');
print "--\n";
print "-- Generated from $0 on " . scalar(localtime) . "\n";
print "--\n";
print "\n";
print join "\n\n", @statements;
print "\n";
