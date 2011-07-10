use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'whitespace'
        }
    },
    params => {
        foobar => '   the quick  brown     fox jumped   over the           ...'
    }
);

ok $v->params->{foobar} =~ /^the quick brown fox jumped over the ...$/,
    'whitespace filter working as expected';