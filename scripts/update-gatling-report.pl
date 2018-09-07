#!/usr/bin/env perl 
use strict;
use warnings;
use Getopt::Long    qw( GetOptions );
use JSON::Syck;
use HTML::TreeBuilder 5 -weak; # Ensure weak references in use

#------------------------------------------------------
# Workflow:
# * take the report folder as input
# * take the CT journal file as input
# * opens and parses the report html index file
# * parses the CT journal:
# * for each action in the run section: 
# *     create a new js file that defines a new var with data for that action. 
#       An action is represented with a 0 value when not active and 1 value when active.
# * updates to the index.html file:
#     * update title to add experiment title
#     * all new js files have to be loaded
#     * the “Responses per second” chart has to be updated and the AllUsersData has to be 
#       replaced with the actions data, the “Active Users” yaxis has to be replaced with “Experiments”
#------------------------------------------------------
my ( $report_dir, $ct_journal_filename );

sub usage {
    die <<EOT;

    Usage: $0 -report_dir <the Gatling report folder> -ct_journal <the chaostoolkit journal filename>

EOT
}

GetOptions(
    "report_dir=s"          => \$report_dir,
    "ct_journal_filename=s" => \$ct_journal_filename
) or die usage();

die usage() unless ( $report_dir && $ct_journal_filename );

die "ChaosToolkit journal file not exists or not readable\n"
    unless -f $ct_journal_filename;


# read the journal and create a single js file for each action and add it to the report folder.
my $ct_journal_data = JSON::Syck::LoadFile($ct_journal_filename);


# * opens and parses the report html index file
my $report_tree = HTML::TreeBuilder->new;
$report_tree->parse_file("$report_dir/index.html")
    or die "Error parsing report html file\n";
