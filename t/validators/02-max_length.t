use Test::More tests => 4;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $r = Validation::Class->new(
    fields => {
        foobar => {
            max_length => 5
        }
    },
    params => {
        foobar => 'apple'
    }
);

ok  $r->validate(), 'foobar validates';
    $r->fields->{foobar}->{max_length} = 4;
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'foobar must contain 4 characters or less' eq $r->errors->to_string(),
    'displays proper error message';
    
#warn $r->errors->to_string();