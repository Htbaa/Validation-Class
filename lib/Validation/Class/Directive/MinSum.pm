# ABSTRACT: MinSum Directive for Validation Class Field Definitions

package Validation::Class::Directive::MinSum;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            invoice_total => {
                min_sum => 1
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

Validation::Class::Directive::MinSum is a core validation class field directive
that validates the numeric value of the associated parameters.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must be greater than %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{min_sum} && defined $param) {

        my $min_sum = $field->{min_sum};

        if ( $field->{required} || $param ) {

            if (int($param) < int($min_sum)) {

                $self->error(@_, $min_sum);

            }

        }

    }

    return $self;

}

1;
