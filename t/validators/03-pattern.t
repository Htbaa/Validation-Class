use Test::More tests => 4;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $r = Validation::Class->new(
    fields => {
        telephone => {
            pattern => '### ###-####'
        }
    },
    params => {
        telephone => '123 456-7890'
    }
);

ok  $r->validate(), 'telephone validates';
    $r->params->{telephone} = '1234567890';
    
ok  ! $r->validate(), 'telephone doesnt validate';
ok  'telephone does not match the pattern ### ###-####' eq $r->errors->to_string(),
    'displays proper error message';
    
#warn $r->errors->to_string();