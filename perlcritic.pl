use File::Find;

my $ver = $ARGV[0] ? "./$ARGV[0]" : ".";

print  "\n";

sub tidy {
    my $file = $File::Find::name ;
    
    system "perlcritic --profile=perlcriticrc $file" if $file =~ /\.pm$/;
}

find \&tidy, $ver;
