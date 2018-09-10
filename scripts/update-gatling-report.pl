#!/usr/bin/env perl 
use strict;
use warnings;
use Getopt::Long    qw( GetOptions );
use GatlingReport   ();
use Log::Log4perl   qw( :easy );

Log::Log4perl->easy_init($DEBUG);

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


my $r = GatlingReport->new( report_dir => $report_dir )
    or die "Error getting a GatlingReport object\n";

$r->parse_report();
$r->add_ct_experiment($ct_journal_filename);
$r->dump_report();
