use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        foobar => {
            filter => 'titlecase'
        }
    },
    params => {
        foobar => 'mr. frank white'
    }
);

ok $v->params->{foobar} =~ /^Mr\. Frank White$/, 'titlecase filter working as expected';