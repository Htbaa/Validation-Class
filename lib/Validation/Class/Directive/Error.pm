# ABSTRACT: Error Directive for Validation Class Field Definitions

package Validation::Class::Directive::Error;

use strict;
use warnings;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Error;

    my $directive = Validation::Class::Directive::Error->new;

=head1 DESCRIPTION

Validation::Class::Directive::Error is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

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
