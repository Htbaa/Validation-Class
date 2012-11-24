# ABSTRACT: Readonly Directive for Validation Class Field Definitions

package Validation::Class::Directive::Readonly;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 DESCRIPTION

Validation::Class::Directive::Readonly is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

sub normalize {

    my ($self, $proto, $field) = @_;

    # respect readonly fields

    if (defined $field->{readonly}) {

        my $name = $field->name;

        # probably shouldn't be deleting the submitted parameters !!!
        delete $proto->params->{$name} if exists $proto->params->{$name};

    }

    return $self;

}

1;
