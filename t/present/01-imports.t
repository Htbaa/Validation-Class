# build
package Example;

use Validation::Class;

# test
package main;

use Test::More;

# check imports
ok do {
    
    my $i = 0;
    
    my $eg = Example;
    
    my @attrs = (
        qw(has attribute bld build dir directive fld field flt filter),
        qw(set load load_classes load_plugins mth method mxn mixin new),
        qw(pro profile)
    );
    
    foreach (@attrs) {
        $i++ if ok $eg->can($_), "package Example has imported $_"
    }
    
    $i == scalar @attrs;
    
}, 'class has imported all desired methods';

done_testing;