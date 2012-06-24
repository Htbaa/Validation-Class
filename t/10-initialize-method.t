BEGIN {
    
    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";
    
}

use utf8;
use Test::More;

{
    
    # testing the initialize method
    # this method is designed to allow the Validation::Class framework to wrap
    # an existing class configuration, most useful with OO systems like Moose, etc
    
    package MyApp;
    
    sub new {
        
        my ($class) = @_;
        
        my $self = bless {}, $class;
        
        return $self;
        
    }
    
    use Validation::Class 'field';
    
    field name => {
    
        required => 1
    
    };
    
    package main;
    
    my $class = "MyApp";
    
    my $self  = $class->new(name => "...");
    
    ok $class eq ref $self, "$class instantiated";
    
    eval { $self->name };
    
    ok $@, "$class has no name field";
    
    $self->initialize;
    
    eval { $self->name };
    
    ok !$@, "$class has a name field";
    
}

done_testing;
