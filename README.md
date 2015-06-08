# NAME

DBIx::Class::InflateColumn::DateTime::WithTimeZone - Store time zones with DateTimes in database

# SYNOPSIS

Set up table with separate column to store time zone, and set that column as
the timezone\_source column for the datetime column.

    package Event;
    use base 'DBIx::Class::Core';

    __PACKAGE__->load_components(qw/InflateColumn::DateTime::WithTimeZone/);

    __PACKAGE_->add_columns(
        event_time => { data_type => 'timestamp', timezone_source => 'event_tz' },
        event_tz   => { data_type => 'varchar', size => 38 },
    );

Store any DateTime into the database

    $dt = DateTime->new( year => 2015, month => 6, day => 8, hour => 9, minute => 10
        time_zone => 'America/Chicago' );

    $row = $schema->resultset('Event')->create( { event_time => $dt } );

In the database, event\_time is now set to the UTC time corresponding to the
original time (2015-06-08T14:10:00), and event\_tz is set to 'America/Chicago'.

When retrieved from the database, event\_time will be returned as an identical
DateTime object, with the same time zone as the original DateTime

    $row = $schema->resultset('Event')->first;

    say $row->event_time . '';                # 2015-06-08T09:10:00

    say $row->event_time->time_zone->name;    # America/Chicago

# DESCRIPTION

This module allows storage and retrieval of DateTime objects while
preserving their time zone. It uses InflateColumn::DateTime to do the
basic inflation / deflation, saving the time zone into a separate
database column when deflating, and applying the time zone when inflating.

Since the DateTime's time zone is preserved, there is no need to have
additional logic to manage the time zone when storing or retrieving in the
database.

The datetime is converted to UTC before storage in the database. This
ensures that the datetime is unambiguous and sortable, because it
avoids ambiguous datetimes that can occur during DST transition.

## Limitations

- The time zone column must be long enough to store the longest
zoneinfo name. Currently, that's 38 characters, but I can't find
any guarantee that will not change.
- Does not preserve locale from the DateTime object. Would this be useful?

## Future Work

- Expand the tests to validate against databases other than SQLite
- Investigate and document interaction with locale
- Add validation of the data\_type and size of the timezone\_source column

## Implementation

### \_ic\_dt\_method

Uses the $info->{\_ic\_dt\_method} value set by InflateColumn::DateTime
to determine the column datatype, rather than duplicating the
detection code

### register\_columns

Wraps register\_columns to validate the column attributes

### \_post\_inflate\_datetime

Sets time zone from the timezone\_source column DateTime inflation

### \_pre\_deflate\_datetime

Sets timezone\_source column to time zone name before DateTime deflation

# AUTHOR

Noel Maddy <zhtwnpanta@gmail.com>

# COPYRIGHT

Copyright 2015- Noel Maddy

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[DBIx::Class::InflateColumn::DateTime](https://metacpan.org/pod/DBIx::Class::InflateColumn::DateTime), [DBIx::Class::InflateColumn](https://metacpan.org/pod/DBIx::Class::InflateColumn), [DateTime](https://metacpan.org/pod/DateTime)
