use Test::More tests => 9;

# load module
BEGIN { use_ok('Validation::Class') }

my $v = Validation::Class->new;

# check attributes
ok $v->fields(  {} ), 'fields attr ok';
ok $v->filters( {} ), 'filters attr ok';
ok $v->params(  {} ), 'params attr ok';
ok $v->mixins(  {} ), 'mixins attr ok';
ok $v->types(   {} ), 'types attr ok';
ok $v->ignore_unknown(1), 'ignore unknown attr ok';
ok $v->report_unknown(1), 'report unknown attr ok';
ok 'Validation::Class::Errors' eq ref $v->errors, 'errors attr ok';
