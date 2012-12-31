# ABSTRACT: Filtering Directive for Validation Class Field Definitions

package Validation::Class::Directive::Filtering;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            telephone_number => {
                filters   => ['numeric']
                filtering => 'post'
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

Validation::Class::Directive::Filtering is a core validation class field
directive that specifies whether filtering and sanitation should occur as a
pre-process or post-process.

=cut

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 0;
has 'dependencies' => sub {{
    normalization => [],
    validation    => []
}};

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # by default fields should have a filtering directive
    # unless already specified

    $field->{filtering} = $proto->filtering || 'pre' if ! defined $field->{filtering};

    return $self;

}

1;
