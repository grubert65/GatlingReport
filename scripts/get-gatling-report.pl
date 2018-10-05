#!/usr/bin/env perl 
use strict;
use warnings;
use DirHandle;

my $results_dir = $ARGV[0] or die "Usage: $0 <results dir>\n";
die "$results_dir not found or not a dir\n" unless -d ( $results_dir );
my $d = DirHandle->new( $results_dir );

my @dirs = sort { (stat $b)[10] <=> (stat $a)[10] }
    map  { "$results_dir/$_" }
    grep { !/^\./ } 
    $d->read();

print $dirs[0] if scalar @dirs;




