use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'alpha'
        }
    },
    params => {
        foobar => 'acb123def456xyz'
    }
);

ok $v->params->{foobar} =~ /^acbdefxyz$/, 'alpha filter working as expected';