# ABSTRACT: MaxDigits Directive for Validation Class Field Definitions

package Validation::Class::Directive::MaxDigits;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::MaxDigits;

    my $directive = Validation::Class::Directive::MaxDigits->new;

=head1 DESCRIPTION

Validation::Class::Directive::MaxDigits is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must contain %s or less digits';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{max_digits} && defined $param) {

        my $max_digits = $field->{max_digits};

        if ( $field->{required} || $param ) {

            my @i = ($param =~ /[0-9]/g);

            if (@i > $max_digits) {

                $self->error(@_, $max_digits);

            }

        }

    }

    return $self;

}

1;
