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

    $event_time = $row->event_time;

    say $event_time . '';                # 2015-06-08T09:10:00

    say $event_time->time_zone->name;    # America/Chicago

# DESCRIPTION

This component preserves the time zone of DateTime objects when
storing and retrieving through DBIx::Class.

It uses InflateColumn::DateTime to do the basic inflation and
deflation. The time zone is saved into an additional database
column, and automatically applied to the DateTime after
inflation.

## UTC-only

The datetime is always converted to UTC before storage in the
database. This ensures that the real time is preserved, no
matter how the clock time is affected by the time zone.

This avoids the problems caused by Daylight Saving Time.
If the datetime were stored in any time zone that has Daylight
Saving Time, then any datetime that occurs during the
transition out of Daylight Saving Time (when the clock goes
back one hour) will be ambiguous. DateTime handles this by
always using the latest real time for the given clock time
(see [DateTime#Ambiguous-Local-Times](https://metacpan.org/pod/DateTime#Ambiguous-Local-Times)). In this case,
any DateTime from the earlier pass through the overlapped times
will be converted to the later time when it is read, effectively
adding the DST offset to the time.

# USAGE NOTES

## Interaction with InflateColumn::DateTime

- Side effects on DateTime object

    Currently, if the timezone attribute is set on InflateColumn::DateTime, then
    the time zone on a DateTime object used to set the column may have its time
    zone changed to that of the timezone attribute. The time zone change only
    happens if the DateTime object is deflated for storage.
    See [https://rt.cpan.org/Public/Bug/Display.html?id=105154](https://rt.cpan.org/Public/Bug/Display.html?id=105154).

    By default, this component overrides this IC::DT behavior. The DateTime
    object used to set the column will not have its time zone changed.

    If you need this side effect, set the DBIC\_IC\_DT\_WTZ\_MODIFY\_TZ environment
    variable, and the IC::DT behavior will be followed: any DateTime used to
    set the column value will have its time zone set to UTC if it has been
    deflated for storage in the database.

- timezone

    The timezone attribute is defaulted to UTC. If a non-UTC timezone
    is specified, an exception will be thrown, since non-UTC time zones
    can not guarantee that the retrieved DateTime matches the saved
    DateTime.

- locale

    The locale attribute is not affected by this component, so it
    should work as documented in InflateColumn::DateTime.

## Nullable columns

If the datetime column is nullable, the timezone\_source column must also
be nullable. If it is not, a exception will be thrown when the schema is
loaded.

## Missing timezone column

If a datetime column with a timezone\_source is included in a ResultSet,
the corresponding timezone\_source column must also be included.

If the timezone\_source column is missing, a runtime exception will be
thrown when the datetime column is accessed.

## Timezone column size

The time zone column must be long enough to store the longest
zoneinfo name. Currently, that's 38 characters, but I can't find
any guarantee that will not change.

This component does not yet validate the timezone column data type
or size. This may result in 

## Implementation Details

This component uses internal methods and data from
[DBIx::Class::InflateColumn::DateTime](https://metacpan.org/pod/DBIx::Class::InflateColumn::DateTime):

### \_ic\_dt\_method

Uses the $info->{\_ic\_dt\_method} value set by InflateColumn::DateTime
to determine the column datatype, rather than duplicating the
detection code.

### \_\_dbic\_colname

Uses the $info->{\_\_dbic\_colname} value set by InflateColumn::DateTime
to provide the column name in error messages.

### register\_columns

Wraps register\_columns to validate the column attributes

### \_post\_inflate\_datetime

Sets time zone from the timezone\_source column DateTime inflation

### \_pre\_deflate\_datetime

Sets timezone\_source column to time zone name before DateTime deflation

# TODO

- Expand the tests to validate against databases other than SQLite
- Investigate and document interaction with locale
- Add validation of the data\_type and size of the timezone\_source column

# AUTHOR

Noel Maddy <zhtwnpanta@gmail.com>

# COPYRIGHT

Copyright 2015- Noel Maddy

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[DBIx::Class::InflateColumn::DateTime](https://metacpan.org/pod/DBIx::Class::InflateColumn::DateTime), [DBIx::Class::InflateColumn](https://metacpan.org/pod/DBIx::Class::InflateColumn), [DateTime](https://metacpan.org/pod/DateTime)
