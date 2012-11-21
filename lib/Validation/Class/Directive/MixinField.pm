# ABSTRACT: MixinField Directive for Validation Class Field Definitions

package Validation::Class::Directive::MixinField;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::MixinField;

    my $directive = Validation::Class::Directive::MixinField->new;

=head1 DESCRIPTION

Validation::Class::Directive::MixinField is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

1;
