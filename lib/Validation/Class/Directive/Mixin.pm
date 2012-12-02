# ABSTRACT: Mixin Directive for Validation Class Field Definitions

package Validation::Class::Directive::Mixin;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        mixins => {
            basic => {
                required => 1,
                filters  => ['trim', 'strip']
            }
        }
        fields => {
            full_name => {
                mixin => 'basic'
            }
        }
    );

    # set parameters to be validated
    $rules->params->add($parameters);

    # validate
    unless ($rules->validate) {
        # handle the failures
    }

=head1 DESCRIPTION

Validation::Class::Directive::Mixin is a core validation class field directive
that determines what directive templates will be merged with the associated
field.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 1;

1;
