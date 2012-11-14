# ABSTRACT: Value Directive for Validation Class Field Definitions

package Validation::Class::Directive::Value;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Value;

    my $directive = Validation::Class::Directive::Value->new;

=head1 DESCRIPTION

Validation::Class::Directive::Value is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin' => 1;
has 'field' => 1;
has 'multi' => 1;

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    # set the field value

    $field->{value} = ($field->{default} || $param) || '';

    return $self;

}

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    # set the field value

    $field->{value} = ($field->{default} || $param) || '';

    return $self;

}

sub normalize {

    my ($self, $proto, $field, $param) = @_;

    # set the field value

    $field->{value} = ($field->{default} || $param) || '';

    return $self;

}

1;
