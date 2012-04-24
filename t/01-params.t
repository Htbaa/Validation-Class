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
        
        my $name_param = $self->name($v);
        
        ok $self->params->{name} eq $name_param,  
            "$class name parameter set to `$v` using the name accessor"
        
    }
    
}

{
    
    package TestClass::ArrayParameters;
    use Validation::Class;
    
    bld sub {
        shift->name([1..5])
    };
    
    fld name => {
        required => 1
    };
    
    package main;
    
    my $class = "TestClass::ArrayParameters";
    my $self  = $class->new;
    
    ok $class eq ref $self, "$class instantiated";
    
    ok "ARRAY" eq ref $self->name, "$class name accessor returns an array";
    
    ok ! $self->params->{name}, "$class flattened name param which is an array";
    
    ok 1 == $self->params->{'name:0'}
    && 2 == $self->params->{'name:1'}
    && 3 == $self->params->{'name:2'}
    && 4 == $self->params->{'name:3'}
    && 5 == $self->params->{'name:4'},
        "$class name param has all expected flatten values";
    
    ok "ARRAY" eq ref $self->name,
        "$class name accessor returns the unflattened array";
    
    ok 5 == grep(/name/, $self->params->keys),
        "$class params collection has 5 name elements";

    ok "HASH" eq ref $self->name({ first => 'Zoi', last => 'Lee' }),
        "$class name accessor has been set as a hashref";
    
    ok 2 == grep(/name/, $self->params->keys),
        "$class params collection has 2 name elements (first and last)";
    
}

done_testing;