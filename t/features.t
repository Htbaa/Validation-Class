
BEGIN {
    
    use FindBin;
    use lib $FindBin::Bin . "/lib/";
    
}

use Test::More;
use Test::Qcmbr;

# build criteria
given
    
    qr(a class name of ([\w:]+)) => sub {
        
        my ($spec, $action, $data, $class) = @_;
        
        use_ok $class;
        
        $self = $class;
        
        ok $class, $action;
        
    };

given
    
    qr(new object from class ([\w:]+)) => sub {
        
        my ($spec, $action, $data, $class) = @_;
        
        use_ok $class;
        
        $self = $class->new;
        
        ok $self->isa($class), $action;
        
    };

when

    qr(pass the (.*) method the key :name and value :value) => sub {
        
        my ($spec, $action, $data, $method, $name, $value) = @_;
        
        ok $self->$method($name, $value), $action;
        
    };

then

    qr(the (\w+) attribute key :name will be :value) => sub {
        
        my ($spec, $action, $data, $attr, $name, $value) = @_;
        
        ok $self->$attr->{$name} eq $value, $action;
        
    };
    
then

    qr(the (\w+) attribute key :name will exist) => sub {
        
        my ($spec, $action, $data, $attr, $name) = @_;
        
        ok $self->$attr->{$name}, $action;
        
    };

then

    qr(the object should have an :attribute attribute) => sub {
        
        my ($spec, $action, $data, $name) = @_;
        
        ok $self->$name, $action;
        
    };

then

    qr(the class should have a :method method) => sub {
        
        my ($spec, $action, $data, $name) = @_;
        
        ok $self->can($name), $action;
        
    };

then
    
    qr(validating .* :name .* :value will :result) => sub {
        
        my ($spec, $action, $data, $name, $value, $result) = @_;
        
        $value = undef if $value eq '~';
        
        if ($result eq 'pass') {
            
            ok $self->validate($name), $action;
            
        }
        
        else {
            
            ok ! $self->validate($name), $action;
            
        }
        
    };

# start running tests
foreach my $feature (glob $FindBin::Bin . "/features/*.feat") {
    
    my $spec = parse_feature_file $feature;

    my $self;
    
    ok 1 => "Specification OK: $feature";
    ok 1 => "Testing Feature: $spec->{name}";
    ok 1 => join ", ", @{$spec->{description}};
    
    execute_scenarios sub {
        
        # before each scenario
        ok 1 => "Starting Scenario: " . shift->{name}
        
    };
    
}

done_testing;