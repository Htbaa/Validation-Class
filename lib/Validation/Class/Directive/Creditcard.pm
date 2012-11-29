# ABSTRACT: Creditcard Directive for Validation Class Field Definitions

package Validation::Class::Directive::Creditcard;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Creditcard is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s requires a valid credit card number';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{creditcard}) {

        my $ccre = {
            'amex'       => qr/^3[4|7]\d{13}$/,
            'bankcard'   => qr/^56(10\d\d|022[1-5])\d{10}$/,
            'diners'     => qr/^(?:3(0[0-5]|[68]\d)\d{11})|(?:5[1-5]\d{14})$/,
            'disc'       => qr/^(?:6011|650\d)\d{12}$/,
            'electron'   => qr/^(?:417500|4917\d{2}|4913\d{2})\d{10}$/,
            'enroute'    => qr/^2(?:014|149)\d{11}$/,
            'jcb'        => qr/^(3\d{4}|2100|1800)\d{11}$/,
            'maestro'    => qr/^(?:5020|6\d{3})\d{12}$/,
            'mastercard' => qr/^5[1-5]\d{14}$/,
            'solo'       => qr/^(6334[5-9][0-9]|6767[0-9]{2})\d{10}(\d{2,3})?$/,
            'switch'     => qr/^(?:49(03(0[2-9]|3[5-9])|11(0[1-2]|7[4-9]|8[1-2])|36[0-9]{2})\d{10}(\d{2,3})?)|(?:564182\d{10}(\d{2,3})?)|(6(3(33[0-4][0-9])|759[0-9]{2})\d{10}(\d{2,3})?)$/,
            'visa'       => qr/^4\d{12}(\d{3})?$/,
            'voyager'    => qr/^8699[0-9]{11}$/,
            # or do a simple catch-all match
            'any'        => qr/^(?:4[0-9]{12}(?:[0-9]{3})?|5[1-5][0-9]{14}|6011[0-9]{12}|3(?:0[0-5]|[68][0-9])[0-9]{11}|3[47][0-9]{13})$/
        };

        my $type = $field->{creditcard};

        if (defined $param) {

            my $is_valid = 0;

            $type = isa_arrayref($type) ? $type : $type eq '1' ? ['any'] : [$type];

            for (@{$type}) {

                if ($param =~ $ccre->{$_}) {
                    $is_valid = 1;
                    last;
                }

            }

            $self->error($proto, $field) unless $is_valid;

        }

    }

    return $self;

}

1;
