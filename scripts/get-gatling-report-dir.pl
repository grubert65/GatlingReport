#!/usr/bin/env perl 
#===============================================================================
#
#         FILE: get-gatling-report-dir.pl
#
#        USAGE: ./get-gatling-report-dir.pl  
#
#  DESCRIPTION: Given a gatling log file, extract the results folder...
#
#      OPTIONS: ---
# REQUIREMENTS: ---
#         BUGS: ---
#        NOTES: ---
#       AUTHOR: Marco Masetti (), marco.masetti@sky.uk
# ORGANIZATION: SKY uk
#      VERSION: 1.0
#      CREATED: 09/13/2018 15:25:42
#     REVISION: ---
#===============================================================================
use strict;
use warnings;
use File::Slurp     'read_file';
use File::Basename  'fileparse';

my $file = $ARGV[0] or die "Usage: get-gatling-report-dir.pl <gatling log file>\n";

my $log = read_file( $file );

if ( $log =~ /Please open the following file: (.*)\n/ ) {
    my ($name,$path,$suffix) = fileparse($1);
    chop $path;
    print $path;
}



