use Test::More tests => 1;

# load module
package MyVal;
use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {foobar => {filters => 'numeric'}},
    params => {foobar => '123abc456def'}
);

ok $v->params->{foobar} =~ /^123456$/, 'numeric filter working as expected';
