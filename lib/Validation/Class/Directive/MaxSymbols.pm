# ABSTRACT: MaxSymbols Directive for Validation Class Field Definitions

package Validation::Class::Directive::MaxSymbols;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::MaxSymbols;

    my $directive = Validation::Class::Directive::MaxSymbols->new;

=head1 DESCRIPTION

Validation::Class::Directive::MaxSymbols is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must contain %s or less non-alphabetic-numeric characters';

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
