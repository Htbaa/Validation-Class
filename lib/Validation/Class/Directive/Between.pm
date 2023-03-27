# ABSTRACT: Between Directive for Validation Class Field Definitions

package Validation::Class::Directive::Between;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            person_age  => {
                between => '18-95'
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

Validation::Class::Directive::Between is a core validation class field directive
that provides the ability to validate the numeric range of the associated
parameters.

=over 8

=item * alternative argument: an-array-of-numbers

This directive can be passed a single value or an array of values:

    fields => {
        person_age  => {
            between => [18, 95]
        }
    }

=back

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 1;
has 'message' => '%s must be between %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{between} && defined $param) {

        my $between = $field->{between};

        if ( $field->{required} || $param ) {

            my ( $min, $max )
                = isa_arrayref($between)
                ? @{$between} > 1
                ? @{$between}
                : (split /(?:\s{1,})?\D{1,}(?:\s{1,})?/, $between->[0])
                : (split /(?:\s{1,})?\D{1,}(?:\s{1,})?/, $between);

            $min = scalar($min);
            $max = scalar($max);

            # warn $min, ',', $max, ',', $param;

            unless ( $param >= $min && $param <= $max ) {

                $self->error(@_, "$min-$max");

            }

        }

    }

    return $self;

}

1;
