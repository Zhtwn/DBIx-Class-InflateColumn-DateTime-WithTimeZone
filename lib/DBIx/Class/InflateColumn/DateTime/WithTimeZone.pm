package DBIx::Class::InflateColumn::DateTime::WithTimeZone;

use strict;
use warnings;
use base 'DBIx::Class::Core';

our $VERSION = '0.01_01';

# you can simply `use base 'InflateColumn::DateTime'; ` instead
__PACKAGE__->load_components( qw/InflateColumn::DateTime/ );

sub register_column {
    my ( $self, $column, $info, @rest ) = @_;

    $self->next::method( $column, $info, @rest );

    if ( my $tz_source = $info->{timezone_source} ) {
        my $ic_dt_method = $info->{_ic_dt_method};
        my $msg = "Column $column:";
        if ( !$ic_dt_method || !$ic_dt_method =~ /(?: datetime | timestamp )/x ) {
            $self->throw_exception( "$msg timezone_source requires datetime data_type");
        }

        my $tz_col = $self->column_info($tz_source);
        if ( !$tz_col ) {
            $self->throw_exception( "$msg could not find column $tz_col for timezone_source" );
        }

        # force InflateColumn::DateTime to convert to UTC before storing
        $info->{timezone} ||= 'UTC';
        # that seems like an artificial limitation... is there a technical reason for it?
        if ( $info->{timezone} ne 'UTC' ) {
            $self->throw_exception( "$msg saving non-UTC datetimes in database is not supported" );
        }
    }
}

sub _post_inflate_datetime {
    my ( $self, $dt, $info ) = @_;

    $dt = $self->next::method( $dt, $info );

    if ( my $tz_src = $info->{timezone_source} ) {
        # you need to call ->has_column_loaded and/or deal with NULLs correctly
        # DT->set_time_zone will barf in a very unhelpful way
        $dt->set_time_zone( $self->get_column($tz_src) );
    }

    return $dt;
}

sub _pre_deflate_datetime {
    my ( $self, $dt, $info ) = @_;

    if ( my $tz_src = $info->{timezone_source} ) {
        $self->set_column( $tz_src, $dt->time_zone->name );
    }

    # HACK - protect DateTime argument from changing
    # that's hardly a hack - it is the documented DT API
    $dt = $self->next::method( $dt->clone, $info );

    return $dt;
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::InflateColumn::DateTime::WithTimeZone - Store time zones with DateTimes in database

=head1 SYNOPSIS

Set up table with separate column to store time zone, and set that column as
the timezone_source column for the datetime column.

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

In the database, event_time is now set to the UTC time corresponding to the
original time (2015-06-08T14:10:00), and event_tz is set to 'America/Chicago'.

When retrieved from the database, event_time will be returned as an identical
DateTime object, with the same time zone as the original DateTime

  $row = $schema->resultset('Event')->first;

  say $row->event_time . '';                # 2015-06-08T09:10:00

  say $row->event_time->time_zone->name;    # America/Chicago

=head1 DESCRIPTION

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

=head2 Limitations

=over

=item *

The time zone column must be long enough to store the longest
zoneinfo name. Currently, that's 38 characters, but I can't find
any guarantee that will not change.

=item *

Does not preserve locale from the DateTime object. Would this be useful?

=back

=head2 Future Work

=over

=item *

Expand the tests to validate against databases other than SQLite

=item *

Investigate and document interaction with locale

=item *

Add validation of the data_type and size of the timezone_source column

=back

=head2 Implementation

=head3 _ic_dt_method

Uses the $info->{_ic_dt_method} value set by InflateColumn::DateTime
to determine the column datatype, rather than duplicating the
detection code

=head3 register_columns

Wraps register_columns to validate the column attributes

=head3 _post_inflate_datetime

Sets time zone from the timezone_source column DateTime inflation

=head3 _pre_deflate_datetime

Sets timezone_source column to time zone name before DateTime deflation

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBIx::Class::InflateColumn::DateTime>, L<DBIx::Class::InflateColumn>, L<DateTime>

=cut
