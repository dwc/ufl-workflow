#!/usr/bin/env perl

use strict;
use warnings;
use Getopt::Long;
use Net::LDAP;

use FindBin;
use lib "$FindBin::Bin/../lib";
use UFL::Workflow::Schema;

=head1 NAME

ufl_workflow_convert_glids.pl - Convert GatorLink IDs to a new field for authentication

=head1 SYNOPSIS

    ./script/ufl_workflow_convert_glids.pl --db-password=xxxxx --ldap-password=xxxxx

=head1 DESCRIPTION

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
    my $db_dsn             = 'dbi:DB2:p01t03wa';
    my $db_username        = 'dbzwap02';
    my $db_password        = '';
    my $db_schema_name     = 'WORKFLOW_DWC';
    my $ldap_host          = 'ldap.ufl.edu',
    my $ldap_dn            = 'cn=02010601/app/webadmin,dc=ufl,dc=edu';
    my $ldap_password      = '';
    my $ldap_base          = 'ou=People,dc=ufl,dc=edu';
    my $from_field         = 'uid';
    my $to_field           = 'uflEduUniversityId';
    my $display_name_field = 'displayName';
    my $mail_field         = 'mail';
    my $help               = 0;
    die usage() unless GetOptions(
        'dsn|d=s'           => \$db_dsn,
        'username|u=s'      => \$db_username,
        'db-password|p=s'   => \$db_password,
        'schema=s'          => \$db_schema_name,
        'host|H=s'          => \$ldap_host,
        'dn|D=s'            => \$ldap_dn,
        'ldap-password|S=s' => \$ldap_password,
        'base|B=s'          => \$ldap_base,
        'from|f=s'          => \$from_field,
        'to|t=s'            => \$to_field,
        'display-name|n=s'  => \$display_name_field,
        'mail|m=s'          => \$mail_field,
        'help|h'            => \$help,
    );
    print usage() and exit() if $help;

    my %options = (
        RaiseError         => 1,
        PrintError         => 0,
        ShowErrorStatement => 1,
        TraceLevel         => 0,
        AutoCommit         => 1,
        db2_set_schema     => uc($db_schema_name),
    );

    my $total = 0;
    my $num_updated = 0;
    my (@missing, @extra);

    my $schema = UFL::Workflow::Schema->connect($db_dsn, $db_username, $db_password, \%options);
    my $ldap = Net::LDAP->new($ldap_host) or die $@;

    my $mesg;
    $mesg = $ldap->bind($ldap_dn, password => $ldap_password);
    $mesg->code and die $mesg->error;

    $schema->txn_do(sub {
        my $users = $schema->resultset('User')->search({}, { order_by => 'username' });

        while (my $user = $users->next) {
            $total++;

            # Assume the user in inactive until we find her
            $user->active(0);

            my $uid = $user->username;
            $mesg = $ldap->search(
                base   => $ldap_base,
                filter => "($from_field=$uid)",
            );

            my $num_entries = $mesg->count;
            if ($num_entries == 0) {
                push @missing, $uid;
            }
            elsif ($num_entries > 1) {
                push @extra, $uid;
            }
            else {
                my $entry = $mesg->shift_entry;
                my $ufid = $entry->get_value($to_field);
                my $display_name = $entry->get_value($display_name_field);
                my $mail = $entry->get_value($mail_field);

                $user->active(1);
                $user->username($ufid);
                $user->display_name($display_name);

                if ($mail) {
                    # Fallback to current default (glid@ufl.edu)
                    $user->email($mail);
                }

                $num_updated++;
            }

            # Make sure we mark the user inactive
            $user->update;
        }
    });

    print "Updated $num_updated of $total user" . ($total == 1 ? '' : 's');

    if (@missing) {
        print "\n\n";
        print list_heading('Users not found in LDAP', @missing);
        print indent_list(@missing);
    }

    if (@extra) {
        print "\n\n";
        print list_heading('Users with more than one entry in LDAP', @missing);
        print indent_list(@extra);
    }
}


##
## Subroutines
##

sub usage {
    return <<"END_OF_USAGE";
Usage: $0 [OPTION]...

Available options:
  -d, --dsn              The DBI data source (e.g. dbi:DB2:p01t03wa)
  -u, --username         The username to connect with
  -p, --db-password      The password to connect with
      --schema           The schema to operate on
  -H, --host             The LDAP host to connect to
  -D, --dn               The bind DN to connect to LDAP with
  -S, --ldap-password    The LDAP password
  -B, --base             The LDAP base (e.g. ou=People,dc=ufl,dc=edu)
  -f, --from             LDAP field to search for usernames
  -t, --to               LDAP field to pull new username values from
  -n, --display-name     LDAP field to set display name to
  -m, --mail             LDAP field to set email address to
  -h, --help             Print this help screen and exit
END_OF_USAGE
}

sub list_heading {
    my ($heading, @list) = @_;

    return "$heading (" . scalar(@list) . "):\n";
}

sub indent_list {
    my (@list) = @_;

    my $spaces = ' ' x 4;
    return $spaces . join("\n$spaces", @list) . "\n";
}
