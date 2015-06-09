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

my $now = DateTime->now( time_zone => 'America/Chicago' );
my $now_utc = $now->clone->set_time_zone('UTC');

my $row = $resultset->create(
    {
        id     => 1,
        ts     => $now,
        ts_utc => $now,
    }
);

$row->discard_changes;

my $parser = $schema->storage->datetime_parser;

for my $col_name (qw{ ts ts_utc }) {
    my $val = $row->$col_name;
    my $info = $row->column_info($col_name);
    isa_ok( $val, 'DateTime', "$col_name column" );
    is( $val,                  $now . '',         '  DateTime corect' );
    is( $val->time_zone->name, 'America/Chicago', '  time zone correct' );

    my ( $raw_str, $raw_val );
    $schema->storage->dbh_do(
        sub {
            my ( $storage, $dbh ) = @_;
            my $vals =
              $dbh->selectcol_arrayref("SELECT $col_name FROM tz WHERE id = 1");
            $raw_str = $vals->[0];
            $raw_val = $parser->parse_datetime( $raw_str, time_zone => $info->{timezone} );
        }
    );

    my $expected_dt = $col_name eq 'ts_oth' ? $now : $now_utc;
    is( $raw_val . '', $expected_dt . '', "$col_name column raw value correct" )
      or diag "database datetime: $raw_str";
}

done_testing;
