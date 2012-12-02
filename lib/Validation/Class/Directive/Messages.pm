# ABSTRACT: Messages Directive for Validation Class Field Definitions

package Validation::Class::Directive::Messages;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            username => {
                required   => 1,
                min_length => 5,
                messages => {
                    required   => '%s is mandatory',
                    min_length => '%s is not the correct length'
                }
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

Validation::Class::Directive::Messages is a core validation class field
directive that holds error message which will supersede the default error
messages of the associated directives.

=cut

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 0;

1;
