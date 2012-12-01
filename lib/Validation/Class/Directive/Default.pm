# ABSTRACT: Default Directive for Validation Class Field Definitions

package Validation::Class::Directive::Default;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Default is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'        => 1;
has 'field'        => 1;
has 'multi'        => 1;
has 'dependencies' => sub {{
    normalization => ['filters'],
    validation    => ['value']
}};

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    # override parameter value if default exists

    if (defined $field->{default} && ! defined $param) {

        my $name = $field->name;

        $proto->params->add($name, $field->{default});

    }

    return $self;

}

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    # override parameter value if default exists

    if (defined $field->{default} && ! defined $param) {

        my $name = $field->name;

        $proto->params->add($name, $field->{default});

    }

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # override parameter value if default exists

    if (defined $field->{default} && ! defined $param) {

        my $name = $field->name;

        $proto->params->add($name, $field->{default});

    }

    return $self;

}

1;
