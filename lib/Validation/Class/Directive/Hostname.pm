# ABSTRACT: Hostname Directive for Validation Class Field Definitions

package Validation::Class::Directive::Hostname;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            company_domain => {
                hostname => 1
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

Validation::Class::Directive::Hostname is a core validation class field
directive that handles validatation of server hostnames.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s requires a valid hostname';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{hostname}) {

        if (defined $param) {

            my $hnre = qr/^(?:[-_a-z0-9][-_a-z0-9]*\.)*(?:[a-z0-9][-a-z0-9]{0,62})\.(?:(?:[a-z]{2}\.)?[a-z]{2,4}|museum|travel)$/;

            $self->error($proto, $field) unless $param =~ $hnre;

        }

    }

    return $self;

}

1;
