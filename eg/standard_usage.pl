#!/usr/env/perl

use strict;
use warnings;

use lib '../lib';

package This::Validation;
use Validation::Class;

field 'users:login' => {
    required => 1
};

field 'users:password' => {
    required => 1
};

package This::Application;

my $input = This::Validation->new({ 'users:login' => 1, 'users:password' => undef });
print scalar $input->validate('users:login', 'users:password') . "\n";
# $input->validate({ login => 'users:login', password => 'users:password' });

1;