use Test::More tests => 5;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
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
ok  'foobar must contain exactly 1 character' eq $r->errors_to_string(),
    'displays proper error message';
    
    $r->params->{foobar} = 'a';
    $r->fields->{foobar}->{length} = 2;
    
ok  ! $r->validate(), 'foobar doesnt validate';
ok  'foobar must contain exactly 2 characters' eq $r->errors_to_string(),
    'displays proper error message';
    
#warn $r->errors_to_string();