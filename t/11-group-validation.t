use Test::More tests => 27;

# load module
BEGIN { use_ok( 'Validation::Class' ) }

my $v = Validation::Class->new(
    fields => {
        'user:login' => {
            error => 'login error'
        },
        'user:password' => {
            error => 'password error',
            min_length => 3,
            max_length => 9,
            pattern => 'XXX######'
        }
    },
    params => {
        'user:login' => 'member',
        'user:password' => 'abc123456'
    }
);

ok $v, 'class initialized';
ok defined $v->fields->{'user:login'}, 'login field exists';
ok defined $v->params->{'user:login'}, 'login param exists';

# check min_length directive
$v->fields->{'user:login'}->{min_length} = 10;
ok ! $v->validate('user:login'), 'error found as expected';
ok ! $v->validate, 'alternate use of validation found error also';
ok $v->errors->count == 1, 'error count is correct';
ok $v->errors->to_string eq 'login error', 'error message specified captured';

$v->fields->{'user:login'}->{min_length} = 5;
ok $v->validate('user:login'), 'user:login rule validates';
ok $v->validate, 'alternate use of validation validates';
ok $v->errors->count == 0, 'error count is zero';
ok $v->errors->to_string eq '', 'no error messages found';

# check max_length directive
$v->fields->{'user:login'}->{max_length} = 5;
ok ! $v->validate('user:login'), 'error found as expected';
ok ! $v->validate, 'alternate use of validation found error also';
ok $v->errors->count == 1, 'error count is correct';
ok $v->errors->to_string eq 'login error', 'error message specified captured';

$v->fields->{'user:login'}->{max_length} = 9;
ok $v->validate('user:login'), 'user:login rule validates';
ok $v->validate, 'alternate use of validation validates';
ok $v->errors->count == 0, 'error count is zero';
ok $v->errors->to_string eq '', 'no error messages found';

# grouped fields perform like normal fields, now testing validation and
# extraction routines

ok $v->validate_groups('user', [qw/login password/]), 'group validation successful';
ok $v->validate_groups('user'), 'group validation successful without specific fields';

my $user = $v->get_group_params();

ok "HASH" eq ref $user && ! keys %{$user}, 'get_group_params returned an empty hash';
$user = $v->get_group_params('user');
ok defined $user->{login} && $user->{login}, 'get_group_params returned hash with login key';
ok defined $user->{password} && $user->{password}, 'get_group_params returned hash with password key';
$user = $v->get_group_params('user' => 'login');
ok defined $user->{login} && $user->{login}, 'get_group_params(1) returned hash with login key';
ok ! defined $user->{password} && ! $user->{password}, 'get_group_params(1) returned hash with password key';

