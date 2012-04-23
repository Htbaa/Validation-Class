BEGIN {
    
    use FindBin;
    use lib $FindBin::Bin . "/lib";
    
}

use utf8;
use open qw/:std :utf8/;
use Test::More;

{
    
    package TestClass::CheckParameters;
    use Validation::Class;
    
    fld name => {
        required => 1
    };
    
    package main;
    
    my $class = "TestClass::CheckParameters";
    my $self  = $class->new;
    
    ok $class eq ref $self, "$class instantiated";
    
    my @vals = qw(
        Kathy
        Joe
        John
        O
        1
        234
        Ricky
        ~
        '
        Lady
        §§
        ♠♣♥♦♠♣♥♦♠♣♥♦
    );
    
    for my $v (@vals) {
        
        ok $v eq $self->name($v),  
            "$class name accessor set to `$v` with expected return value"
        
    }
    
    for my $v (@vals) {
        
        ok $self->params->{name} eq $self->name($v),  
            "$class name parameter set to `$v` using the name accessor"
        
    }
    
    ok $class->name;
    
}

done_testing;