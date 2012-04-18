package MyApp::Test::B;

use Validation::Class;

fld login       => {
    mixin       => 'basic',
    min_length  => 5
};
 
fld password    => {
    mixin       => 'basic',
    min_length  => 5,
    min_symbols => 1
};

1;