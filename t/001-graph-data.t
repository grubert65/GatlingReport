use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok("GatlingReport::GraphData");
}

ok( my $o = GatlingReport::GraphData->new(), 'new' );

ok( my @time_seq = $o->get_time_sequence( './data/exp1/gatling-report/js/all_sessions.js'), 'get_time_sequence' );

my $data =  [];

foreach ( @time_seq ) {
    push @$data, [ $_, 0 ];
}

ok( $o->name('Foo') );
ok( $o->color('#050505') );
ok( my $out = $o->process( $data ), 'process' );

done_testing;




