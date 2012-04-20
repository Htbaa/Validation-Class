BEGIN {
    
    use FindBin;
    use lib $FindBin::Bin . "/lib";
    
}

use Test::More;

{
    
    # test class, no importing - #fail
    
    package BareClass;
    use Validation::Class ();
    
    package main;
    
    my $class ;
    
    eval { $class = BareClass->new };
    
    ok ! $class, "BareClass cannot be instantiated wo/definitions or importing";
    
}

{
    
    # test class, no importing - #hack
    
    package BareClass::Hack;
    use Validation::Class ();
    
    Validation::Class->setup(__PACKAGE__);
    
    package main;
    
    my $class = BareClass::Hack->new;
    
    ok "BareClass::Hack" eq ref $class,
    "BareClass::Hack instantiated, via the setup hack";
    
    ok ! $class->can($_),
    "BareClass::Hack has NOT been injected with the $_ method" for qw/
        attribute
        bld
        build
        dir
        directive
        fld
        field
        flt
        filter
        has
        load
        mth
        method
        mxn
        mixin
        pro
        profile
        set
    /;
    
    ok $class->can($_),
    "BareClass::Hack has been injected with the $_ method" for qw/
        new
        proto
        prototype
        
        class
        clear_queue
        copy_errors
        error
        error_count
        error_fields
        errors
        errors_to_string
        get_errors
        fields
        filtering
        ignore_failure
        ignore_unknown
        param
        params
        queue
        report_failure
        report_unknown
        reset_errors
        set_errors
        stash
        
        validate
        validate_profile
    /;
    
}

{
    
    # test class, traditional usage
    
    package BareClass::Traditional;
    use Validation::Class;
    
    package main;
    
    my $class = BareClass::Traditional->new;
    
    ok "BareClass::Traditional" eq ref $class,
    "BareClass::Traditional instantiated, via the setup hack";
    
    ok $class->can($_),
    "BareClass::Traditional has been injected with the $_ method" for qw/
        attribute
        bld
        build
        dir
        directive
        fld
        field
        flt
        filter
        has
        load
        mth
        method
        mxn
        mixin
        pro
        profile
        set
    /;
    
    ok $class->can($_),
    "BareClass::Traditional has been injected with the $_ method" for qw/
        new
        proto
        prototype
        
        class
        clear_queue
        copy_errors
        error
        error_count
        error_fields
        errors
        errors_to_string
        get_errors
        fields
        filtering
        ignore_failure
        ignore_unknown
        param
        params
        queue
        report_failure
        report_unknown
        reset_errors
        set_errors
        stash
        
        validate
        validate_profile
    /;
    
}

{
    
    # test class, overriding injected methods (all)
    
    package BareClass::Overrider;
    use Validation::Class;
    
    sub attribute { 'noop' }
    sub bld       { 'noop' }
    sub build     { 'noop' }
    sub dir       { 'noop' }
    sub directive { 'noop' }
    sub fld       { 'noop' }
    sub field     { 'noop' }
    sub flt       { 'noop' }
    sub filter    { 'noop' }
    sub has       { 'noop' }
    sub load      { 'noop' }
    sub mth       { 'noop' }
    sub method    { 'noop' }
    sub mxn       { 'noop' }
    sub mixin     { 'noop' }
    sub pro       { 'noop' }
    sub profile   { 'noop' }
    sub set       { 'noop' }

    sub new       { 'noop' }
    sub proto     { 'noop' }
    sub prototype { 'noop' }

    sub class            { 'noop' }
    sub clear_queue      { 'noop' }
    sub copy_errors      { 'noop' }
    sub error            { 'noop' }
    sub error_count      { 'noop' }
    sub error_fields     { 'noop' }
    sub errors           { 'noop' }
    sub errors_to_string { 'noop' }
    sub get_errors       { 'noop' }
    sub fields           { 'noop' }
    sub filtering        { 'noop' }
    sub ignore_failure   { 'noop' }
    sub ignore_unknown   { 'noop' }
    sub param            { 'noop' }
    sub params           { 'noop' }
    sub queue            { 'noop' }
    sub report_failure   { 'noop' }
    sub report_unknown   { 'noop' }
    sub reset_errors     { 'noop' }
    sub set_errors       { 'noop' }
    sub stash            { 'noop' }

    sub validate         { 'noop' }
    sub validate_profile { 'noop' }
    
    package main;
    
    my $class = bless {}, 'BareClass::Overrider';
    
    ok "BareClass::Overrider" eq ref $class, "BareClass::Overrider instantiated";
    
    ok 'noop' eq $class->$_,
    "BareClass::Overrider method $_ method was overriden" for qw/
        attribute
        bld
        build
        dir
        directive
        fld
        field
        flt
        filter
        has
        load
        mth
        method
        mxn
        mixin
        pro
        profile
        set
    /;
    
    ok ! do { eval { 1 if 'noop' eq $class->$_ }; $@ },
    "BareClass::Overrider method $_ method was overriden" for qw/
        new
        proto
        prototype
        
        class
        clear_queue
        copy_errors
        error
        error_count
        error_fields
        errors
        errors_to_string
        get_errors
        fields
        filtering
        ignore_failure
        ignore_unknown
        param
        params
        queue
        report_failure
        report_unknown
        reset_errors
        set_errors
        stash
        
        validate
        validate_profile
    /;
    
}

done_testing;