# ABSTRACT: SSN Directive for Validation Class Field Definitions

package Validation::Class::Directive::SSN;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            user_ssn => {
                ssn => 1
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

Validation::Class::Directive::SSN is a core validation class field directive
that handles validation of social security numbers in the USA.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not a valid social security number';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{ssn}) {

        if (defined $param) {

            my $ssnre = qr/\A\b(?!000)[0-9]{3}-[0-9]{2}-[0-9]{4}\b\z/i;
            $self->error($proto, $field) unless $param =~ $ssnre;

        }

    }

    return $self;

}

1;
