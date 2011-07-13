use Test::More tests => 6;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $r = Validation::Class->new(
    fields => {
        status => {
            options => 'Active, Inactive'
        }
    },
    params => {
        status  => 'Active'
    }
);

ok  $r->validate(), 'status is valid';
    $r->params->{status} = 'active';
    
ok  ! $r->validate(), 'status case doesnt match';
ok  'status must be Active or Inactive' eq $r->errors->to_string(),
    'displays proper error message';
    
    $r->params->{status} = 'inactive';
    
ok  ! $r->validate(), 'status case doesnt match alt';
    
    $r->params->{status} = 'Inactive';
    
ok  $r->validate(), 'alternate status value validates';
    
#warn $r->errors->to_string();