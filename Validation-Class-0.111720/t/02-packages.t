use Test::More tests => 7;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

package MyApp::Test;

use Validation::Class qw/field mixin filter/;
use base 'Validation::Class';

field 'field01' => {
    required    => 1,
    min_length  => 1,
    max_length  => 255,
};

package main;

my $v = MyApp::Test->new;

# check attributes
ok $v->params,  'params attr ok';
ok $v->fields,  'fields attr ok';
ok $v->mixins,  'mixins attr ok';
ok $v->filters, 'filters attr ok';
ok $v->types,   'types attr ok';
ok 'Validation::Class::Errors' eq ref $v->errors,   'errors attr ok';