#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Validation::Class' );
}

diag( "Testing Validation::Class $Validation::Class::VERSION, Perl $], $^X" );
