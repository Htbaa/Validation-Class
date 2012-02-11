use Test::More tests => 31;

# begin
use_ok 'Validation::Class::Simple';

my $a_profile = {
    name => {
        required => 1,
        label    => 'my name',
        filters  => [qw/trim strip titlecase/],
        error    => 'name not right'
    }
};

my $b_profile = {
    login => {
        required  => 1,
        label     => 'my login',
        filters   => [qw/trim strip lowercase alphanumeric/],
        filtering => 'post',
        pattern   => qr/^[a-zA-Z0-9]+$/,
        error     => 'login not right'
    }
};

my $a_rules = Validation::Class::Simple->new(
    ignore_unknown => 1,
    fields => $a_profile,
    params => {}
);

# diag 'run $a_profile instance';

ok $a_rules, 'validation class init ok';
ok $a_rules->validate(), 'validation passes (explicit ignore set) as expected';
ok !$a_rules->validate('name'),
  'validation fails (field set explicitly) as expected';
ok $a_rules->errors_to_string eq 'name not right', 'error message as expected';

$a_rules->params->{name} = ' someone SPECIAL     ';

ok $a_rules->apply_filters, 'applied filters';
ok $a_rules->params->{name} =~ /^Someone Special$/, 'filtering as expected';
ok $a_rules->validate, 'validation passed ok';

my $b_rules = Validation::Class::Simple->new(
    ignore_unknown => 1,
    fields => $b_profile,
    params => {}
);

# diag 'run $b_profile instance';

ok $b_rules, 'validation class init ok';
ok $b_rules->validate(), 'validation passes (explicit ignore set) as expected';
ok !$b_rules->validate('login'), 'validation fails (field set explicitly) as expected';
ok $b_rules->errors_to_string eq 'login not right', 'error message as expected';

$b_rules->params->{login} = ' someone SPECIAL     ';

ok $b_rules->apply_filters, 'applied filters';
ok $b_rules->params->{login} =~ /^ someone SPECIAL     $/, 'filtering as expected';
ok !$b_rules->validate, 'validation failed ok';

$b_rules->params->{login} = 'someoneSPECIAL';

ok $b_rules->validate, 'validation passed ok';
ok $b_rules->params->{login} =~ /^someonespecial$/, 'filtering as expected post validation';

# diag 're-run $a_profile instance';

$a_rules->params({});

ok $a_rules, 'validation class init ok';
ok $a_rules->validate(), 'validation passes (explicit ignore set) as expected';
ok !$a_rules->validate('name'),
  'validation fails (field set explicitly) as expected';
ok $a_rules->errors_to_string eq 'name not right', 'error message as expected';

$a_rules->params->{name} = ' someone SPECIAL     ';

ok $a_rules->apply_filters, 'applied filters';
ok $a_rules->params->{name} =~ /^Someone Special$/, 'filtering as expected';
ok $a_rules->validate, 'validation passed ok';

# diag 're-run $b_profile instance with $a_profile';

$b_rules->fields($a_profile);
$b_rules->params({});

ok $b_rules, 'validation class init ok';
ok $b_rules->validate(), 'validation passes (explicit ignore set) as expected';
ok !$b_rules->validate('name'),
  'validation fails (field set explicitly) as expected';
ok $b_rules->errors_to_string eq 'name not right', 'error message as expected';

$b_rules->params->{name} = ' someone SPECIAL     ';

ok $b_rules->apply_filters, 'applied filters';
ok $b_rules->params->{name} =~ /^Someone Special$/, 'filtering as expected';
ok $b_rules->validate, 'validation passed ok';
