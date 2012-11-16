# ABSTRACT: Filtering Directive for Validation Class Field Definitions

package Validation::Class::Directive::Filtering;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Filtering;

    my $directive = Validation::Class::Directive::Filtering->new;

=head1 DESCRIPTION

Validation::Class::Directive::Filtering is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 1;

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # by default fields should have a filtering directive
    # unless already specified

    unless (defined $field->{filtering}) {

        $field->{filtering} = $proto->filtering || 'pre';

    }

    return $self;

}

1;
