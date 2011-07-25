use Test::More tests => 2;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $r = Validation::Class->new(
    fields => {
        status => {
            # ...
        }
    },
    params => {
        _dc => '1310548813350',
        id  => 'i4jiojtrgijeriogjrtiorjwgoitjr'
    },
    ignore_unknown => 1
);

# resolve the anomyly
ok  $r->validate('_foo'), 'valid by default';

#warn $r->errors->to_string();