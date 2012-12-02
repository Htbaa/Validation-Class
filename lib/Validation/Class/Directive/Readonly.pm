# ABSTRACT: Readonly Directive for Validation Class Field Definitions

package Validation::Class::Directive::Readonly;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            task_completed => {
                readonly => 1
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

Validation::Class::Directive::Readonly is a core validation class field
directive that determines whether the associated parameters should be ignored.

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
