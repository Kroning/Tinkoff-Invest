#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Tinkoff::Invest' ) || print "Bail out!\n";
}

diag( "Testing Tinkoff::Invest $Tinkoff::Invest::VERSION, Perl $], $^X" );
