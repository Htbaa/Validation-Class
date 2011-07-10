use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'currency'
        }
    },
    params => {
        foobar => '$2000.99'
    }
);

ok $v->params->{foobar} =~ /^2000\.99$/, 'currency filter working as expected';