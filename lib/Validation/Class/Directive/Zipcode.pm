# ABSTRACT: Zipcode Directive for Validation Class Field Definitions

package Validation::Class::Directive::Zipcode;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            address_zipcode => {
                zipcode => 1
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

Validation::Class::Directive::Zipcode is a core validation class field directive
that handles postal-code validation for areas in the USA and North America.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not a valid postal code';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{zipcode}) {

        if (defined $param) {

            my $zcre = qr/\A\b[0-9]{5}(?:-[0-9]{4})?\b\z/i;
            $self->error($proto, $field) unless $param =~ $zcre;

        }

    }

    return $self;

}

1;
