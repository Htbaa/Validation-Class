use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'alphanumeric'
        }
    },
    params => {
        foobar => '1@%23abc45@%#@#%6d666ef..'
    }
);

ok $v->params->{foobar} =~ /^123abc456d666ef$/, 'alphanumeric filter working as expected';
