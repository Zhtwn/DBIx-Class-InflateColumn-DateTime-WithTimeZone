use strict;
use Test::More;
use DateTime;

use lib qw( t/lib );

eval "use Test::NonUtcSchema";

# FIXME - better verification of error message
isnt( $@, undef, 'timestamp_source with missing column gives error' );

done_testing;
