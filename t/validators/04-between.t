use Test::More tests => 4;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $r = Validation::Class->new(
    fields => {
        foobar => {
            between => '2-5'
        }
    },
    params => {
        foobar => 'apple'
    }
);

ok  $r->validate(), 'foobar validates';
    $r->params->{foobar} = '#';
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'foobar must contain between 2-5 characters' eq $r->errors->to_string(),
    'displays proper error message';
    
#warn $r->errors->to_string();