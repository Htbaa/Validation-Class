# ABSTRACT: Pattern Directive for Validation Class Field Definitions

package Validation::Class::Directive::Pattern;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Pattern;

    my $directive = Validation::Class::Directive::Pattern->new;

=head1 DESCRIPTION

Validation::Class::Directive::Pattern is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not formatted properly';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{pattern}) {

        my $pattern = $field->{pattern};

        if (defined $param) {

            unless ( isa_regexp($pattern) ) {

                $pattern =~ s/([^#X ])/\\$1/g;
                $pattern =~ s/#/\\d/g;
                $pattern =~ s/X/[a-zA-Z]/g;
                $pattern = qr/$pattern/;

            }

            unless ( $param =~ $pattern ) {

                $self->error($proto, $field);

            }

        }

    }

    return $self;

}

1;
