#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'GatlingReport' ) || print "Bail out!\n";
}

diag( "Testing GatlingReport $GatlingReport::VERSION, Perl $], $^X" );
