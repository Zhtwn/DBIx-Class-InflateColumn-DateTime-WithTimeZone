use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );
use Test::Schema;

my $schema = Test::Schema->connect('dbi:SQLite:dbname=:memory:', '', '');
$schema->deploy;

my $resultset = $schema->resultset('Tz');

my $result_source = $resultset->result_source;

is( $result_source->column_info('ts')->{timezone},
    'UTC', 'timezone defaults to UTC' );

is( $result_source->column_info('ts_utc')->{timezone},
    'UTC', 'explicit UTC timezone correct' );

is( $result_source->column_info('ts_oth')->{timezone},
    'America/Chicago', 'explicit non-UTC timezone correct' );

my $now = DateTime->now( time_zone => 'America/Chicago' );

my $row = $resultset->create(
    {
        id     => 1,
        ts     => $now,
        ts_utc => $now,
        ts_oth => $now,
    }
);

$row->discard_changes;

for my $col_name (qw{ ts ts_utc ts_oth }) {
    my $val = $row->$col_name;
    isa_ok( $val, 'DateTime', "$col_name column" );
    is( $val,                  $now . '',         '  DateTime corect' );
    is( $val->time_zone->name, 'America/Chicago', '  time zone correct' );
}

done_testing;
