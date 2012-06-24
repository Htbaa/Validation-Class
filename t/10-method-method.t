BEGIN {
    
    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";
    
}

use utf8;
use Test::More;

{
    
    # testing the method method
    # this method is designed to ....
    
    package MyApp;
    
    use Validation::Class;
    
    fld name => {
    
        required => 1
    
    };
    
    mth print_name => {
        input => ['name'],
        using => sub {
            my ($self) = @_;
            return "my name is " . $self->name
        }
    };
    
    package main;
    
    my $class = "MyApp";
    my $self  = $class->new();
    
    ok $class eq ref $self, "$class instantiated";
    ok !$self->print_name, "no name printed because the name field is null";
    
    $self->name("echo");
    
    ok "my name is echo" eq $self->print_name, "name printed as intended";
    
}

done_testing;
