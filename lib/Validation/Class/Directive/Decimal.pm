# ABSTRACT: Decimal Directive for Validation Class Field Definitions

package Validation::Class::Directive::Decimal;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Decimal is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s requires a valid decimal number';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{decimal}) {

    # checks for a valid decimal. Both the sign and exponent are optional

    # 0 => Any number of decimal places, including none
    # 1 => Any number of decimal places greater than 0, or a float|double
    # 2 => Exactly that many number of decimal places

        if (defined $param) {

            my $type = $field->{decimal};

            my $lnum = '[0-9]+';
            my $dnum = "[0-9]*[\.]{$lnum}";
            my $sign = '[+-]?';
            my $exp  = "(?:[eE]{$sign}{$lnum})?";

            my $dre;

            if ($type == 0) {
                $dre = qr/^{$sign}(?:{$lnum}|{$dnum}){$exp}$/;
            }

            elsif ($type == 1) {
                $dre = qr/^{$sign}{$dnum}{$exp}$/;
            }

            else {
                $type = "[0-9]\{$type}";
                $dnum = "(?:[0-9]*[\.]{$type}|{$lnum}[\.]{$type})";
                $dre = qr/^{$sign}{$dnum}{$exp}$/;
            }

            $self->error($proto, $field) unless $param =~ $dre;

        }

    }

    return $self;

}

1;
