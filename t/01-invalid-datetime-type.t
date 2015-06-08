use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );

eval "use Test::NonDateTimeSchema";

# FIXME - better verification of error message
isnt( $@, undef, 'timestamp_source on non-datetime column gives error' );

done_testing;
