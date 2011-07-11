use Test::More tests => 8;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $r = Validation::Class->new(
    fields => {
        password => {
            matches => 'password2'
        },
        password2 => {
            # ....
        },
    },
    params => {
        password  => 'secret',
        password2 => 'secret',
    }
);

ok  $r->validate(), 'password validates';
    $r->params->{password2} = 's3cret';
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'password does not match password2' eq $r->errors->to_string(),
    'displays proper error message';
    
    $r->fields->{password}->{label}  = 'pass (a)';
    $r->fields->{password2}->{label} = 'pass (b)';
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'pass (a) does not match pass (b)' eq $r->errors->to_string(),
    'displays proper error message';
    
    $r->params->{password2} = '';
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'pass (a) does not match pass (b)' eq $r->errors->to_string(),
    'displays proper error message';
    
#warn $r->errors->to_string();