use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'lowercase'
        }
    },
    params => {
        foobar => '123ABC456DEF'
    }
);

ok $v->params->{foobar} =~ /^123abc456def$/, 'lowercase filter working as expected';
