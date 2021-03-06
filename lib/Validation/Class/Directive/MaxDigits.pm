# ABSTRACT: MaxDigits Directive for Validation Class Field Definitions

package Validation::Class::Directive::MaxDigits;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            password => {
                max_digits => 12
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

Validation::Class::Directive::MaxDigits is a core validation class field
directive that validates the length of numeric characters in the associated
parameters.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must not contain more than %s digits';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{max_digits} && defined $param) {

        my $max_digits = $field->{max_digits};

        if ( $field->{required} || $param ) {

            my @i = ($param =~ /[0-9]/g);

            if (@i > $max_digits) {

                $self->error(@_, $max_digits);

            }

        }

    }

    return $self;

}

1;
