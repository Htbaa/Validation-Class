# ABSTRACT: Errors Directive for Validation Class Field Definitions

package Validation::Class::Directive::Errors;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Errors is a core validation class field directive
that holds error message registered at the field-level for the associated field.
This directive is used internally.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

1;
