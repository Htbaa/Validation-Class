package MyApp::Test::A;

use Validation::Class;

mxn clean => {
    filters => [qw/trim strip/]
}; 
 
fld login       => {
    mixin       => 'basic',
    min_length  => 5
};
 
fld password    => {
    mixin       => 'basic',
    min_length  => 5,
    min_symbols => 1
};
 
bld sub {
    
    shift->login('admin')
    
};

1;