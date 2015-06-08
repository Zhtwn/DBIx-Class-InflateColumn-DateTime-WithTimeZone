use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );
use Test::Schema;

my $schema = Test::Schema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

my $resultset = $schema->resultset('UtcTz');

my $result_source = $resultset->result_source;

is( $result_source->column_info('ts')->{timezone},
    'UTC', 'timezone set to UTC' );

my $now = DateTime->now( time_zone => 'America/Chicago' );

my $row = $resultset->create(
    {
        id         => 1,
        ts         => $now,
    }
);

$row->discard_changes;

my $ts = $row->ts;
isa_ok( $ts, 'DateTime', 'ts column' );
is( $ts,                  $now . '',         '  DateTime corect' );
is( $ts->time_zone->name, 'America/Chicago', '  time zone correct' );

done_testing;
