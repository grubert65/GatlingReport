use strict;
use warnings;
use Test::More;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init($DEBUG);

BEGIN {
    use_ok("GatlingReport");
}

ok( my $o = GatlingReport->new(
        report_dir  => './data/exp1/gatling-report',
    ), 'new' );

ok( $o->parse_report(), 'parse_report' );
ok( $o->add_ct_experiment('./data/exp1/journal.json'), 'add_ct_experiment');
ok( $o->dump_report(), 'dump_report' );

done_testing;



