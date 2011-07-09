use Test::More tests => 21;

# load module
use Validation::Class;

# declare validation rules
mixin 'basic'  => {
    required   => 1,
    min_length => 1,
    max_length => 255,
    filters    => ['lowercase', 'alphanumeric']
};

mixin 'validation'  => {};

field 'login'  => {
    mixin      => 'basic',
    label      => 'user login',
    error      => 'login invalid',
    validation => sub {
	my ($self, $this, $fields) = @_;
	return $this->{value} eq 'admin' ? 1 : 0;
    }
};

field 'password'  => {
    mixin         => 'basic',
    label         => 'user password',
    error         => 'password invalid',
    validation    => sub {
	my ($self, $this, $fields) = @_;
	return $this->{value} eq 'pass' ? 1 : 0;
    }
};

field 'something' => {
    mixin         => ['basic', 'validation']
};

# verfiy rules are set
ok defined $Validation::Class::MIXINS->{basic}, 'basic mixin set';
ok defined $Validation::Class::FIELDS->{login}, 'login field set';
ok defined $Validation::Class::FIELDS->{password}, 'password field set';

# create instance
my $v = Validation::Class->new;
ok $v, 'instance created';

# verify fields received mixins
ok defined $v->fields->{login}->{required} &&
   defined $v->fields->{login}->{min_length} &&
   defined $v->fields->{login}->{max_length},
   'login field received mixin';
ok defined $v->fields->{password}->{required} &&
   defined $v->fields->{password}->{min_length} &&
   defined $v->fields->{password}->{max_length},
   'password field received mixin';

# check attributes
ok $v->params,  'params attr ok';
ok $v->fields,  'fields attr ok';
ok $v->mixins,  'mixins attr ok';
ok $v->filters, 'filters attr ok';
ok $v->types,   'types attr ok';

# process field with multiple mixins
ok defined $v->fields->{something}->{required} &&
   defined $v->fields->{something}->{min_length} &&
   defined $v->fields->{something}->{max_length},
   'something field generated from multiple mixins';

# define grouped fields
field 'auth:login'  => {
    mixin           => 'basic',
    label           => 'user login',
    error           => 'login invalid',
    validation      => sub {
	my ($self, $this, $fields) = @_;
	return $this->{value} eq 'admin' ? 1 : 0;
    }
};

field 'auth:password'  => {
    mixin              => 'basic',
    label              => 'user password',
    error              => 'password invalid',
    validation         => sub {
	my ($self, $this, $fields) = @_;
	return $this->{value} eq 'pass' ? 1 : 0;
    }
};

field 'user:name' => {
    mixin         => 'basic',
    label         => 'user name',
    error         => 'invalid name',
    validation    => sub {
	my ($self, $this, $fields) = @_;
	return 1;
    }
};

field 'user:phone'=> {
    mixin         => 'basic',
    label         => 'user phone',
    error         => 'phone invalid',
    validation    => sub {
	my ($self, $this, $fields) = @_;
	return 0;
    }
};

field 'user:email'=> {
    mixin         => 'basic',
    label         => 'user email',
    error         => 'email invalid',
    validation    => sub {
	my ($self, $this, $fields) = @_;
	return 1;
    }
};

my $params = {
     login => 'admin1%^&%&^%^%&',
     password => 'pass@@@#$#%$^',
     name => 'al newkirk',
     phone => '2155551212',
     email => 'awncorp2cpan.org',
     password_cfm => ''
};

$v = Validation::Class->new(params => $params);

# params set at new function
ok scalar(keys %{$v->params}), 'params have been set at instantiation';

# error class exists
ok 'Validation::Class::Errors' eq ref $v->errors, 'error class setup';

# validate login only
ok ! $v->validate({login => 'auth:login'}), 'login field failed as expected';
ok $v->errors->count == 1, 'error count accurate';
ok $v->errors->to_string eq 'login invalid', 'error messages and error class to_string method works';

# check formatting
ok $v->params->{login} eq 'admin1', 'login formatting worked';
ok $v->params->{password} eq 'pass', 'password formatting worked';

# process common password confirmation
field 'password_cfm' => {
     mixin_field => 'password',
     value => 'pass',
     validation => sub {
	my ($self, $this, $fields) = @_;
	return
		lc($this->{value}) eq lc($fields->{password}) ? 1 : 0;
     }
};
ok $v->validate('password'), 'password field validates';
ok $v->validate('password', 'password_cfm'), 'password confirmation validates';
