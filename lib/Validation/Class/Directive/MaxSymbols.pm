# ABSTRACT: MaxSymbols Directive for Validation Class Field Definitions

package Validation::Class::Directive::MaxSymbols;

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
                max_symbols => 30
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

Validation::Class::Directive::MaxSymbols is a core validation class field
directive that validates the length of non-alphanumeric characters in the
associated parameters.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must not contain more than %s special characters';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{max_symbols} && defined $param) {

        my $max_symbols = $field->{max_symbols};

        if ( $field->{required} || $param ) {

            my @i = ($param =~ /[^a-zA-Z0-9]/g);

            if (@i > $max_symbols) {

                $self->error(@_, $max_symbols);

            }

        }

    }

    return $self;

}

1;
