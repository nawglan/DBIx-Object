#!perl -T

use Test::More tests => 1;
use JSON;

BEGIN {
  use_ok( 'DBIx::Object' );
}

my $test_hash = {
  name => 'Some Name',
  array => ['a','b', 3, 5],
  hash => {
    key1 => 'val1',
    key2 => {key4 => 'c', key5 => 4, key6 => ['c', 'd', 7, 9]},
    key3 => 'val3'
  },
  regex => qr/thisisaregex/x,
  code => sub {return 1},
  id => 4,
  globref => \*STDERR,
  glob => *STDERR,
  obj => JSON->new
};

$test_hash->{circ_name} = \$test_hash->{name};
$test_hash->{circ_top} = $test_hash;
$test_hash->{circ_array} = $test_hash->{array};

my @results = processRef $test_hash;

diag( "Testing processing of an object" );
