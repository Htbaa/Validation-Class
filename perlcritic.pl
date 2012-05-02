#!/usr/bin/perl

use File::Find::Rule;

my $ver = $ARGV[0] ? "./$ARGV[0]" : ".";

print  "\n";

my @files = File::Find::Rule->file()->name('*.pm')->in($ver);

foreach my $file (@files) {

	print "processing $file\n";
	system "perlcritic --profile=perlcriticrc $file" 
		if $file =~ /\.pm$/;

}

