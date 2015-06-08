package Test::Schema::Result::Tz;

use base 'DBIx::Class::Core';

__PACKAGE__->table('tz');
__PACKAGE__->load_components('InflateColumn::DateTime::WithTimeZone');

__PACKAGE__->add_columns(
    id     => { data_type => 'integer' },
    ts     => { data_type => 'timestamp', timezone_source => 'tz' },
    tz     => { data_type => 'varchar' },
    ts_utc => { data_type => 'timestamp', timezone_source => 'tz_utc', timezone => 'UTC' },
    tz_utc => { data_type => 'varchar' },
    ts_oth => { data_type => 'timestamp', timezone_source => 'tz_oth', timezone => 'America/Chicago' },
    tz_oth => { data_type => 'varchar' },
);

# need primary key so discard_changes works
__PACKAGE__->set_primary_key('id');

1;
