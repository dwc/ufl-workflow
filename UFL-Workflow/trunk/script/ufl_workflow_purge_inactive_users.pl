#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;

use FindBin;
use lib "$FindBin::Bin/../lib";
use UFL::Workflow::Schema;

=head1 NAME

ufl_workflow_generate_schema.pl - Generate the schema for UFL::Workflow

=head1 SYNOPSIS

    ./script/ufl_workflow_generate_schema.pl | db2 -vtd%

=head1 DESCRIPTION

Generate the SQL statements for L<UFL::Workflow::Schema>.

=head1 AUTHOR

Daniel Westermann-Clark E<lt>dwc@ufl.eduE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

##
## Main script
##

main(@ARGV);
sub main {
    my $dsn         = 'dbi:DB2:p01t03wa';
    my $username    = 'dbzwap02';
    my $password    = '';
    my $schema_name = 'WORKFLOW_DWC';
    my $help        = 0;
    die usage() unless GetOptions(
        'dsn|d=s'       => \$dsn,
        'username|u=s'  => \$username,
        'password|p=s'  => \$password,
        'schema|s=s'    => \$schema_name,
        'help|h'        => \$help,
    );
    print usage() and exit() if $help;

    my %options = (
        RaiseError         => 1,
        PrintError         => 0,
        ShowErrorStatement => 1,
        TraceLevel         => 0,
        AutoCommit         => 1,
        db2_set_schema     => uc($schema_name),
    );

    my $total = 0;
    my $num_deleted = 0;

    my $schema = UFL::Workflow::Schema->connect($dsn, $username, $password, \%options);
    $schema->txn_do(sub {
        my $users = $schema->resultset('User');

        while (my $user = $users->next) {
            $total++;

            my $num_related = $user->processes->count
                + $user->requests->count
                + $user->actions->count
                + $user->user_group_roles->count;

            if ($num_related == 0) {
                $user->delete;
                $num_deleted++;
            }
        }
    });

    print "Deleted $num_deleted user" . ($num_deleted == 1 ? '' : 's') . " of $total\n";
}


##
## Subroutines
##

sub usage {
    return <<"END_OF_USAGE";
Usage: $0 [OPTION]...

Available options:
  -d, --dsn            The DBI data source (e.g. dbi:DB2:p01t03wa)
  -u, --username       The username to connect with
  -p, --password       The password to connect with
  -s, --schema         The schema to operate on
  -h, --help           Print this help screen and exit
END_OF_USAGE
}
