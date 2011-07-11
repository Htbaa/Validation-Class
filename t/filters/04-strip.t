use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'strip'
        }
    },
    params => {
        foobar => '   the quick  brown     fox jumped   over the           ...'
    }
);

ok $v->params->{foobar} =~ /^the quick brown fox jumped over the ...$/,
    'strip filter working as expected';