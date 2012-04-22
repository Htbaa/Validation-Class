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
    
    my $class = TestClass::CheckParameters->new;
    
    ok "TestClass::CheckParameters" eq ref $class,
    "TestClass::CheckParameters instantiated";
    
    ok $_ eq $class->name($_),  
    "TestClass::CheckParameters name accessor set to `$_` with expected return ".
    "value" for (
        'Kathy',
        'Joe',
        'John',
        'O',
        '1',
        1234,
        'Ricky',
        '~',
        '',
        'Lady',
        '§§',
        '♠♣♥♦♠♣♥♦♠♣♥♦'
    );
    
    ok $class->params->{name} eq $class->name($_),  
    "TestClass::CheckParameters name parameter set to `$_` using ".
    "the name accessor" for (
        'Kathy',
        'Joe',
        'John',
        'O',
        '1',
        1234,
        'Ricky',
        '~',
        '',
        'Lady',
        '§§',
        '♠♣♥♦♠♣♥♦♠♣♥♦'
    );
    
    ok $class->params->{name} eq $class->name($_), 
    "TestClass::CheckParameters name parameter set to `$_` using ".
    "the name accessor" for (
        'Kathy',
        'Joe',
        'John',
        'O',
        '1',
        1234,
        'Ricky',
        '~',
        '',
        'Lady',
        '§§',
        '♠♣♥♦♠♣♥♦♠♣♥♦'
    );
    
}

done_testing;