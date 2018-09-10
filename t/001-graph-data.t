use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok("GatlingReport::GraphData");
}

ok( my $o = GatlingReport::GraphData->new(), 'new' );

ok( my $time_seq = $o->get_time_sequence( './data/exp1/gatling-report/js/all_sessions.js'), 'get_time_sequence' );

ok( my $data = $o->set_on_off_time_sequence(
        time_sequence   => $time_seq, 
        switch_on_time  => 1536318951, 
        duration        => 0.01379), 'set_on_off_time_sequence');


ok( $o->name('Foo') );
ok( $o->color('#050505') );
ok( my $out = $o->process( $data ), 'process' );

done_testing;




