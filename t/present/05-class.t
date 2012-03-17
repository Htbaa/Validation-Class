use Test::More;

# check class method
do {
    
    # build
    package Example::Something;
    
    use Validation::Class;
    
    package Example;
    
    use Validation::Class;
    
    set {
        class => 'Example::Something'
    };
    
    # test
    package main;
    
    my $i;
    
    my $example  = Example->new(params => {'a'..'d'});
    my $relatives = $example->relatives;
    
    $i=0;
    
    $i++ if $example->relatives->{'something'} eq 'Example::Something';
    $i++ if $example->relatives->{'Something'} eq 'Example::Something';
    
    ok $i == 2, 'Example has 2 relative pointers, something and Something';
    
    my $something = $example->class('something');
    
    ok 'Example::Something' eq ref $something,
        'class method returns Example::Something object';
    
    $i=0;
    
    $i++ if $something->params->{'a'} eq 'b';
    $i++ if $something->params->{'c'} eq 'd';
    
    ok $i == 2, 'Example passed Something its parameters';
    ok ! scalar keys %{$something->relatives}, 'Something has no relatives registered';
    
};

done_testing;
