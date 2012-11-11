# ABSTRACT: Toggle Directive for Validation Class Field Definitions

package Validation::Class::Directive::Toggle;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Toggle;

    my $directive = Validation::Class::Directive::Toggle->new;

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

        my $stash = $proto->stash->{'directive.toggle'};

        # to be restored after validation
        $stash->{$field->{name}}->{'required'} = $field->{required};

        $field->{required} = 1 if ($field->{toggle} =~ /^([+]|1)$/);
        $field->{required} = 0 if ($field->{toggle} =~ /^([-]|0)$/);

    }

    return $self;

}

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{toggle}) {

        my $stash = $proto->stash->{'directive.toggle'};

        # restore field state from stash after validation
        $field->{required} = $stash->{$field->{name}}->{'required'};
        delete $stash->{$field->{name}};

    }

    return $self;

}

1;
