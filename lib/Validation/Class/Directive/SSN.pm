# ABSTRACT: SSN Directive for Validation Class Field Definitions

package Validation::Class::Directive::SSN;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::SSN is a core validation class
field directive that provides the ability to do some really cool stuff only we
haven't documented it just yet.

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
