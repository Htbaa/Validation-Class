# ABSTRACT: Pattern Directive for Validation Class Field Definitions

package Validation::Class::Directive::Pattern;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            company_email => {
                pattern => qr/\@company\.com$/
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

Validation::Class::Directive::Pattern is a core validation class field directive
that validates simple patterns and complex regular expressions.

=over 8

=item * alternative argument: an-array-of-something

This directive can be passed a regexp object or a simple pattern. A simple
pattern is a string where the `#` character matches digits and the `X` character
matches alphabetic characters.

    fields => {
        task_date => {
            pattern => '##-##-####'
        },
        task_time => {
            pattern => '##:##:##'
        }
    }

=back

=cut

has 'mixin'   => 1;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s is not formatted properly';

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{pattern} && defined $param) {

        my $pattern = $field->{pattern};

        if ($field->{required} || $param) {

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
