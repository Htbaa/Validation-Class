# ABSTRACT: Options Directive for Validation Class Field Definitions

package Validation::Class::Directive::Options;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Options is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'     => 1;
has 'field'     => 1;
has 'multi'     => 0;
has 'message'   => '%s must be either %s';

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    if (defined $field->{options} && defined $param) {

        my $options = $field->{options};

        if ( $field->{required} || $param ) {

            my (@options) = isa_arrayref($options) ?
                @{$options} : split /(?:\s{1,})?[,\-]{1,}(?:\s{1,})?/, $options
            ;

            unless (grep { $param =~ /^$_$/ } @options) {

                if (my @o = @options) {

                    my$list=(join(' or ',join(', ',@o[0..$#o-1])||(),$o[-1]));

                    $self->error(@_, $list);

                }

            }

        }

    }

    return $self;

}

1;
