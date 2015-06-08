use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );
use Test::Schema;

my $schema = Test::Schema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

my $resultset = $schema->resultset('DefaultTz');

my $result_source = $resultset->result_source;

is( $result_source->column_info('ts')->{timezone},
    'UTC', 'timezone defaults to UTC' );

my $now = DateTime->now( time_zone => 'America/Chicago' );

my $row = $resultset->create(
    {
        id         => 1,
        ts         => $now,
    }
);

$row->discard_changes;

isa_ok( $row->ts, 'DateTime', 'ts column' );
is( $row->ts,                  $now . '', '  DateTime corect' );
is( $row->ts->time_zone->name, 'America/Chicago', '  time zone correct' );

done_testing;
