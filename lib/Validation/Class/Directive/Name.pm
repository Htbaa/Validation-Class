# ABSTRACT: Name Directive for Validation Class Field Definitions

package Validation::Class::Directive::Name;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Name is a core validation class field directive
that merely holds the name of the associated field. This directive is used
internally and the value is populated automatically.

=cut

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 0;

1;
