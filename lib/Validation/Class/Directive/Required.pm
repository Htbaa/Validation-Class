# ABSTRACT: Required Directive for Validation Class Field Definitions

package Validation::Class::Directive::Required;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            search_query => {
                required => 1
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

Validation::Class::Directive::Required is a core validation class field
directive that handles validation of supply and demand.

=cut

has 'mixin'        => 1;
has 'field'        => 1;
has 'multi'        => 0;
has 'message'      => '%s is required';
has 'dependencies' => sub {{
    normalization => [],
    validation    => ['alias', 'toggle']
}};

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{required}) {

        if ($field->{required} && (! defined $param || $param eq '')) {

            $self->error($proto, $field);
            $proto->stash->{'validation.bypass_event'}++;

        }

    }

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # by default, field validation is optional

    $field->{required} = 0 unless defined $field->{required};

    return $self;

}

1;
