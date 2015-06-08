package DBIx::Class::InflateColumn::DateTime::WithTimeZone;

use strict;
use warnings;
use base 'DBIx::Class::Core';

use 5.008_005;
our $VERSION = '0.01';

__PACKAGE__->load_components( qw/InflateColumn::DateTime/ );

# TODO
# - misuse $info->{_ic_dt_method} for now, to get type
# - describe interaction with floating_tz_ok
# - add checks on timezone_source column data_type

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

        $info->{timezone} ||= 'UTC';
        if ( $info->{timezone} ne 'UTC' ) {
            $self->throw_exception( "$msg saving non-UTC datetimes in database is not supported" );
        }
    }
}

sub _post_inflate_datetime {
    my ( $self, $dt, $info ) = @_;

    $dt = $self->next::method( $dt, $info );

    if ( my $tz_src = $info->{timezone_source} ) {
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
    $dt = $self->next::method( $dt->clone, $info );

    return $dt;
}

1;
__END__

=encoding utf-8

=head1 NAME

DBIx::Class::InflateColumn::DateTime::WithTimeZone - Store and retrieve DateTime time zones transparently

=head1 SYNOPSIS

  use DBIx::Class::InflateColumn::DateTime::WithTimeZone;

=head1 DESCRIPTION

DBIx::Class::InflateColumn::DateTime::WithTimeZone is

timezone: sets time zone to be stored in database (default UTC)
timezone_source: column name for actual time zone

=head1 AUTHOR

Noel Maddy E<lt>zhtwnpanta@gmail.comE<gt>

=head1 COPYRIGHT

Copyright 2015- Noel Maddy

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<DBIx::Class::InflateColumn::DateTime>

=cut
