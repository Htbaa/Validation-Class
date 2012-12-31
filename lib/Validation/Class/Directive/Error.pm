# ABSTRACT: Error Directive for Validation Class Field Definitions

package Validation::Class::Directive::Error;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple;

    my $rules = Validation::Class::Simple->new(
        fields => {
            username => {
                error => 'This is not a valid username'
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

Validation::Class::Directive::Error is a core validation class field directive
that holds the error message that will supersede any other error messages that
attempt to register errors at the field-level for the associated field.

=cut

has 'mixin' => 0;
has 'field' => 1;
has 'multi' => 0;

sub normalize {

    my ($self, $proto, $field) = @_;

    # static messages may contain multiline strings for the sake of
    # aesthetics, flatten them here

    if (defined $field->{error}) {

        $field->{error} =~ s/^[\n\s\t\r]+//g;
        $field->{error} =~ s/[\n\s\t\r]+$//g;
        $field->{error} =~ s/[\n\s\t\r]+/ /g;

    }

    return $self;

}

1;
