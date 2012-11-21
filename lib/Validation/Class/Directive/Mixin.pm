# ABSTRACT: Mixin Directive for Validation Class Field Definitions

package Validation::Class::Directive::Mixin;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Mixin;

    my $directive = Validation::Class::Directive::Mixin->new;

=head1 DESCRIPTION

Validation::Class::Directive::Mixin is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 1;

1;
