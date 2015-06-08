package Test::Schema::Result::DefaultTz;

use base 'DBIx::Class::Core';

__PACKAGE__->table('default_tz');
__PACKAGE__->load_components('InflateColumn::DateTime::WithTimeZone');

__PACKAGE__->add_columns(
    id     => { data_type => 'integer' },
    ts     => { data_type => 'timestamp', timezone_source => 'tz' },
    tz     => { data_type => 'varchar' },
);

# need primary key so discard_changes works
__PACKAGE__->set_primary_key('id');

1;
