use Test::More tests => 9;

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
	'name'
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

my $v = Validation::Class->new( automap => 1, params => {
    name  => 'bingowas hisnameo',
    phone => '+10000000000',
    email => 'iamuser@somesite.com'
} );

# values functions
my ($name, $phone, $email) = $v->get_params('name', 'phone', 'email');

ok
    $name && $phone && $email,
    'parameters set';
ok
    $name eq 'bingowas hisnameo' &&
    $email eq 'iamuser@somesite.com' &&
    $phone eq '+10000000000',
    'parameters values are correct';

($name, $email, $phone) = $v->get_params('name', 'email', 'phone');

ok
    $name && $phone && $email,
    'parameters set';
ok
    $name eq 'bingowas hisnameo' &&
    $email eq 'iamuser@somesite.com' &&
    $phone eq '+10000000000',
    'parameters values are correct';
    
$v = Validation::Class->new( automap => 1, params => {
    name  => '',
    phone => '+10000000000',
    email => ''
} );

($name, $email, $phone) = $v->get_params('name', 'email', 'phone');

ok
    !$name && $phone && !$email,
    'parameters set';
ok
    $name eq '' &&
    $email eq '' &&
    $phone eq '+10000000000',
    'parameters values are correct';

$v = Validation::Class->new( automap => 1, params => {
    phone => '+10000000000'
} );

($name, $email, $phone) = $v->get_params('name', 'email', 'phone');

ok
    !$name && $phone && !$email,
    'parameters set';
ok
    ! defined $name &&
    ! defined $email &&
    $phone eq '+10000000000',
    'parameters values are correct';
ok
    !$name &&
    !$email &&
    $phone eq '+10000000000',
    'parameters values are correct';
