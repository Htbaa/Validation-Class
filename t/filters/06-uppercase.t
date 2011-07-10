use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'uppercase'
        }
    },
    params => {
        foobar => '123abc456def'
    }
);

ok $v->params->{foobar} =~ /^123ABC456DEF$/, 'uppercase filter working as expected';
