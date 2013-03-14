use Test::More;

package MyVal;

use Validation::Class;

package main;

my $v = MyVal->new(
    fields => {
        access_key  => {
            default  => 12345,
            required => 1
        },
        access_code => {
            default => sub {
                return ref shift;
            },
            required => 1
        },
    },
    params => {
        access_key  => 'abcde',
        access_code => 'abcdefghi'
    }
);

ok $v, 'class initialized';

ok 'abcde' eq $v->params->get('access_key'), 'access_key has explicit value';
ok 'abcdefghi' eq $v->params->get('access_code'), 'access_code has explicit value';

$v->params->clear;

ok $v->validate('access_code', 'access_key'), 'params validated via default values';

ok 12345 eq $v->params->get('access_key'), 'access_key has default value';
ok 'MyVal' eq $v->params->get('access_code'), 'access_code has default value w/context';

done_testing;
