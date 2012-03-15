use Test::More;

if ($ENV{TEST_MOOSE}) {
    plan tests => 9;
}
else {
    plan skip_all => "No Moose";
}

# begin
package Identify;

use  Moose;
with 'Validation::Class::MooseRules';

has login => (
    is     => 'rw',
    isa    => 'Str',
    traits => ['Rules'],
    rules  => {
        label      => 'User Login',
        error      => 'Login invalid.',
        required   => 1,
        validation => sub {
            my ( $self, $this_field, $all_params ) = @_;
            return $this_field->{value} eq 'admin' ? 1 : 0;
        }
    }
);

has password => (
    is     => 'rw',
    isa    => 'Str',
    traits => ['Rules'],
    rules  => {
        label      => 'User Password',
        error      => 'Password invalid.',
        required   => 1,
        validation => sub {
            my ( $self, $this_field, $all_params ) = @_;
            return $this_field->{value} eq 'pass' ? 1 : 0;
        }
    }
);

package main;

my $id    = Identify->new(login => 'admin', password => 'xxxx');
my $rules = $id->rules;

ok "Identify" eq ref $id, '$id instantiated';
ok $id->login, 'login was set';
ok $id->password, 'password was set';
ok "Validation::Class::Simple" eq ref $rules, '$rules was set with V::C::Simple object';
ok $rules->fields->{login}, 'login attribute rules are set on the V::C::S obj';
ok $rules->fields->{password}, 'password attribute rules are set on the V::C::S obj';
ok ! $rules->validate, 'validation failed as expected';
ok $rules->errors_to_string, 'Password invalid.';
   $rules->params->{password} = 'pass';
ok $rules->validate, 'validation successful';
