use Test::More tests => 1;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'decimal'}},
    params => {foobar => '$2000.99'}
);

ok $v->params->{foobar} =~ /^2000\.99$/, 'currency filter working as expected';
