use Test::More;

if ($ENV{TEST_MOOSE}) {
    plan tests => 3;
}
else {
    plan skip_all => "No Moose";
}

package Foo;
use Moose;
with 'Validation::Class::MooseRules';

has foo => (
    is       => 'ro',
    required => 1,
    traits   => ['Rules'],
    rules    => {
        label      => 'Foo',
        validation => sub {
            my ( $self, $this_field, $all_params ) = @_;
            return $this_field->{value} eq 'foo' ? 1 : 0;
          }
    }
);

package Bar;
use Moose;

extends 'Foo';

with 'Validation::Class::MooseRules';

has bar => (
    is       => 'ro',
    required => 1,
    traits   => ['Rules'],
    rules    => {
        label      => 'Bar',
        validation => sub {
            my ( $self, $this_field, $all_params ) = @_;
            return $this_field->{value} eq 'bar' ? 1 : 0;
          }
    }
);

package main;

my $i = Bar->new( foo => 1, bar => 2 );
my $rules = $i->rules;
ok !$rules->validate, 'Should not validate, values bad';

$i = Bar->new( foo => 'foo', bar => 2 );
$rules = $i->rules;
ok !$rules->validate, 'Should not validate, values bad';

$i = Bar->new( foo => 'foo', bar => 'bar' );
$rules = $i->rules;
ok $rules->validate, 'Should validate';
