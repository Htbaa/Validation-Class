#!/usr/bin/perl

use Test::More;
use FindBin;

use strict;
use warnings;

my $lib     = $FindBin::Bin . "/../lib/";
my @profile = qw(
    -5
    --severity 5
    --exclude Modules::RequireVersionVar
    --exclude TestingAndDebugging::RequireUseStrict
    --exclude TestingAndDebugging::RequireUseWarnings
    --exclude ValuesAndExpressions::ProhibitAccessOfPrivateData
);

ok ! system("perlcritic", @profile, $lib), "library passes critique";

done_testing;
