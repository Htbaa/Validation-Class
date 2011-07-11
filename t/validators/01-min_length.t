use Test::More tests => 4;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $r = Validation::Class->new(
    fields => {
        foobar => {
            min_length => 5
        }
    },
    params => {
        foobar => 'apple'
    }
);

ok  $r->validate(), 'foobar validates';
    $r->fields->{foobar}->{min_length} = 6;
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'foobar must contain 6 or more characters' eq $r->errors->to_string(),
    'displays proper error message';
    
#warn $r->errors->to_string();