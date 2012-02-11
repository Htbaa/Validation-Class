use File::Find;
use FindBin;

my $ver = $ARGV[0] ? "./$ARGV[0]" : ".";

print  "\n";

sub tidy {
    my $dir  = $FindBin::Bin ;
    my $file = $File::Find::name ;
       $file =~ s/^\.\///;
       
    my $filepath = join "/", $dir, $file;
    my $profile  = join "/", $dir, "perltidyrc";
    
    print "\nprocessing $file" if $file =~ /\.(pm|t)$/;
    system "perltidy --profile=$profile $filepath" if $file =~ /\.(pm|t)$/;
    system "rm -f $filepath" if $file =~ /\.pm\.bak$/;
}

find \&tidy, $ver;
