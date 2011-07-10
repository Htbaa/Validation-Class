use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'trim'
        }
    },
    params => {
        foobar => '       0011010101   '
    }
);

ok $v->params->{foobar} =~ /^0011010101$/, 'trim filter working as expected';