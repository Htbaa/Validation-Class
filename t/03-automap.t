use Test::More tests => 3;

# load module
use Validation::Class;

my $passer = sub { 1 };

# define grouped fields
field 'auth:login', {
    label      => 'user login',
    error      => 'login invalid',
    validation => $passer,
    alias      => [
	'user'
    ]
};

field 'auth:password', {
    label      => 'user password',
    error      => 'password invalid',
    validation => $passer,
    alias      => [
	'pass'
    ]
};

field 'user:name', {
    label      => 'user name',
    error      => 'invalid name',
    validation => $passer,
    alias      => [
	'name',
	'user'
    ]
};

field 'user:phone', {
    label      => 'user phone',
    error      => 'phone invalid',
    validation => $passer,
    alias      => [
	'phone'
    ]
};

field 'user:email', {
    label      => 'user email',
    error      => 'email invalid',
    validation => $passer,
    alias      => [
	'email'
    ]
};

eval {
    my $v = Validation::Class->new( automap => 1, params => {
	email => 'iamuser@somesite.com'
    } );
};

ok $@, 'duplicate alias definition error';

$Validation::Class::FIELDS->{'user:name'}->{alias} = 'name';

my $v = Validation::Class->new( automap => 1, params => {
    email => 'iamuser@somesite.com'
} );

ok $v, 'duplicates removed, validation-class initialized';

ok $v->validate(), 'validation works and successful';
