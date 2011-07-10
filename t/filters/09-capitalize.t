use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'capitalize'
        }
    },
    params => {
        foobar => 'i am that I am. this is not going to work. im leaving, good bye.'
    }
);

ok $v->params->{foobar} =~ /^I am that I am. This is not going to work. Im leaving, good bye./,
    'capitalize filter working as expected';
