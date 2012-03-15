use Test::More tests => 3;

package MyVal;
use Validation::Class;

package main;

my $r = MyVal->new(
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
ok  'foobar must contain at-least 6 characters' eq $r->errors_to_string(),
    'displays proper error message';
    
#warn $r->errors_to_string();