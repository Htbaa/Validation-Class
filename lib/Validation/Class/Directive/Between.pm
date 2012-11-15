# ABSTRACT: Between Directive for Validation Class Field Definitions

package Validation::Class::Directive::Between;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Between;

    my $directive = Validation::Class::Directive::Between->new;

=head1 DESCRIPTION

Validation::Class::Directive::Between is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 1;
has 'message' => '%s must contain between %s characters';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{between}) {

        my $between = $field->{between};

        if ( $field->{required} || $param ) {

            my ( $min, $max )
                = isa_arrayref($between)
                ? @{$between}
                : split /(?:\s{1,})?[,\-]{1,}(?:\s{1,})?/, $between;

            $min = scalar($min);
            $max = scalar($max);

            my $value = length($param);

            unless ( $value >= $min && $value <= $max ) {

                $self->error(@_, "$min-$max");

            }

        }

    }

    return $self;

}

1;
