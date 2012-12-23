# ABSTRACT: UUID Directive for Validation Class Field Definitions

package Validation::Class::Directive::UUID;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            user_uuid => {
                uuid => 1
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

Validation::Class::Directive::UUID is a core validation class field directive
that handles validation of Globally/Universally Unique Identifiers.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not a valid UUID';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{uuid} && defined $param) {

        if ($field->{required} || $param) {

            my $ure = qr/^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$/i;

            $self->error($proto, $field) unless $param =~ $ure;

        }

    }

    return $self;

}

1;
