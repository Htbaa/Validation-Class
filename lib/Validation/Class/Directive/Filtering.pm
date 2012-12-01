# ABSTRACT: Filtering Directive for Validation Class Field Definitions

package Validation::Class::Directive::Filtering;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Filtering is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 0;
has 'dependencies' => sub {{
    normalization => [],
    validation    => []
}};

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # by default fields should have a filtering directive
    # unless already specified

    $field->{filtering} = $proto->filtering || 'pre' if ! defined $field->{filtering};

    return $self;

}

1;
