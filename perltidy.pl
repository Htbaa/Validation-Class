#!/usr/bin/perl

use FindBin;
use File::Find::Rule;

my $ver = $ARGV[0] ? "./$ARGV[0]" : ".";

print  "\n";

my $find  = File::Find::Rule;

my @files = $find->file()->name('*.pm','*..t')->in($ver);

foreach my $file (sort @files) {

        print "processing $file\n";
        system "perltidy --profile=perltidyrc $file";

}

my @backups = $find->file()->name('*.pm.bak')->in($ver);

foreach my $file (sort @backups) {

        print "removing backup $file\n";
        unlink $file;

}

