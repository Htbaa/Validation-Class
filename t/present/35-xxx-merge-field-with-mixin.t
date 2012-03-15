# build
package Example;

use Validation::Class;

# test
package main;

use Test::More;

# check methods
ok do {
    
    my $i = 1;
    
    my $eg = Example->new;
    
    # 
    
    $i;
    
}, '...';

done_testing;
