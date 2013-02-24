use FindBin;
use Test::More;

use utf8;
use strict;
use warnings;

{

    package TestClass::MethodCalling;
    use Validation::Class;

    field constraint => {required => 1};

    method check_a => {input => ['constraint']};
    sub _check_a {'check_a OK'}

    method a_check => {input => ['constraint']};
    sub _process_a_check {'check_a OK'}

    package main;

    my $class = "TestClass::MethodCalling";
    my $self  = $class->new;

    ok $class eq ref $self, "$class instantiated";

    $self->constraint('h@ck');

    ok 'check_a OK' eq $self->check_a, "$class check_a method spec'd and validated";
    ok 'check_a OK' eq $self->a_check, "$class a_check method spec'd and validated";

}

done_testing;
