#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Lim' ) || print "Bail out!\n";
}

diag( "Testing Lim $Lim::VERSION, Perl $], $^X" );
