# build
package Example;

use Validation::Class;

# test
package main;

use Test::More;

# check attributes
ok do {
    
    my $i = 0;
    
    my $eg = Example->new;
    
    my @attrs = qw(
        directives
        errors
        fields
        filtering
        filters
        hash_inflator
        ignore_failure
        ignore_unknown
        methods
        mixins
        params
        plugins 
        profiles
        queued
        relatives
        report_failure
        report_unknown
        stashed
        types
    );
    
    foreach my $attr (@attrs) {
        
        $i++ if ok $eg->can($attr),
            "attribute $attr is inherited by package Example";
        
        my $isa = lc ref $eg->$attr;
        
        if ($isa) {
            
            $i++ if ok uc($isa) eq ref do{ $a = $eg->$attr; $eg->$attr($a); $a },
                "attribute $attr holds type:$isa and gets/sets";
        
        }
        
        else {
            
            $i++ if ok 'test' eq do{ $eg->$attr('test'); $eg->$attr },
                "attribute $attr hold type:constant and gets/sets";
            
        }
        
    }
    
    $i == ((scalar @attrs) * 2);
    
}, 'all class attributes appear in tact';


# check methods
ok do {
    
    my $i = 0;
    
    my $eg = Example->new;
    
    my @methods = qw(
        has
        apply_filters
        class
        check_field
        check_mixin
        clear_queue
        clone
        default_value
        error
        error_count
        error_fields
        errors_to_string
        get_classes
        get_errors
        get_params
        get_params_hash
        normalize
        param
        queue
        reset
        reset_errors
        reset_fields
        set_errors
        set_method
        set_params_hash
        stash
        template
        use_filter
        use_mixin
        use_mixin_field
        use_validator
        validate
        validate_profile
        _error_unknown_field
        _merge_mixin
        _merge_field
    );
    
    foreach (@methods) {
        $i++ if ok $eg->can($_), "package Example has method $_"
    }
    
    $i == scalar @methods;
    
}, 'all class methods accounted for';

done_testing;