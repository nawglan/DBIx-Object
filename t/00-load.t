#!perl -T

use Test::More tests => 1;

BEGIN {
  use_ok( 'DBIx::Object' );
}

diag( "Testing DBIx::Object $DBIx::Object::VERSION, Perl $], $^X" )
