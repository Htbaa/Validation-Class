# ABSTRACT: Toggle Directive for Validation Class Field Definitions

package Validation::Class::Directive::Toggle;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Toggle is a core validation class field directive
that provides the ability to toggle a field's `required` directive.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{toggle}) {

        my $stash = $proto->stash->{'directive.toggle'} ||= {};

        # to be restored after validation

        $stash->{$field->{name}}->{'required'} =
            defined $field->{required} ? $field->{required} == 0 ? 0 : 1 : 0;

        $field->{required} = 1 if ($field->{toggle} =~ /^(\+|1)$/);
        $field->{required} = 0 if ($field->{toggle} =~ /^(\-|0)$/);

    }

    return $self;

}

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{toggle}) {

        my $stash = $proto->stash->{'directive.toggle'} ||= {};

        if (defined $stash->{$field->{name}}->{'required'}) {

            # restore field state from stash after validation

            $field->{required} = $stash->{$field->{name}}->{'required'};

            delete $stash->{$field->{name}};

        }

    }

    delete $field->{toggle} if exists $field->{toggle};

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # on normalize, always remove the toggle directive

    delete $field->{toggle} if exists $field->{toggle};

    return $self;

}

1;
