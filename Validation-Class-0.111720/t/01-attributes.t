use Test::More tests => 7;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new;

# check attributes
ok $v->params,  'params attr ok';
ok $v->fields,  'fields attr ok';
ok $v->mixins,  'mixins attr ok';
ok $v->filters, 'filters attr ok';
ok $v->types,   'types attr ok';
ok 'Validation::Class::Errors' eq ref $v->errors,   'errors attr ok';
