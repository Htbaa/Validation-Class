use Test::More tests => 6;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $r = Validation::Class->new(
    fields => {
        foobar => {
            length => '1'
        }
    },
    params => {
        foobar => 'a'
    }
);

ok  $r->validate(), 'foobar validates';
    $r->params->{foobar} = 'abc';
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'foobar must contain exactly 1 character' eq $r->errors->to_string(),
    'displays proper error message';
    
    $r->params->{foobar} = 'a';
    $r->fields->{foobar}->{length} = 2;
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'foobar must contain exactly 2 characters' eq $r->errors->to_string(),
    'displays proper error message';
    
#warn $r->errors->to_string();