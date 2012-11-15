# ABSTRACT: Base Class for Validation Class Directives

package Validation::Class::Directive;

use Validation::Class::Core 'build_args', 'has';
use Carp 'confess';

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive;

    my $validator = Validation::Class::Directive->new(
        mixin     => 0,
        field     => 1,
        multi     => 0,
        validator => sub {

            my ($self, $proto, $field, $param) = @_;

        }
    );

... written as a package

    package Validation::Class::Directive::FooBar;

    use base 'Validation::Class::Directive';
    use Validation::Class::Core;

    has 'mixin' => 0;
    has 'field' => 1;
    has 'multi' => 0;
    has 'message' => '%s was not processed successfully';
    has 'validator' => sub {};

    1;

=head1 DESCRIPTION

Validation::Class::Directive provides a base-class for validation class
directives.

=cut

# defaults

has 'mixin'     => 0;
has 'field'     => 0;
has 'multi'     => 0;
has 'message'   => '%s was not processed successfully';
has 'validator' => sub {1};
has 'name'      => sub {

    my ($self) = @_;

    my $name = ref $self || $self;

    my $regexp = qr/V[^:]+::C[^:]+::D[^:]+::(.*)$/;

    ($name) = $name =~ $regexp;

    $name =~ s/([a-z])([A-Z])/$1_$2/g;
    $name =~ s/\W/_/g;
    $name = lc $name;

    return $name;

};

sub new {

    my $class = shift;

    my $arguments = $class->build_args(@_);

    confess
        "Error creating directive without a name, specifying a name is " .
        "required to instatiate a new non-subclass directive"

        if 'Validation::Class::Directive' eq $class && ! $arguments->{name}

    ;

    my $self = bless {}, $class;

    while (my($key, $value) = each %{$arguments}) {
        $self->$key($value);
    }

    return $self;

}

sub error {

    my ($self, $proto, $field, $param, @tokens) = @_;

    my $name = $field->label || $field->name;

    unshift @tokens, $name;

    # use custom or default error message

    if ($field->error) {
        $field->errors->add($field->error);
    }

    else {
        $field->errors->add(sprintf($self->message, @tokens));
    }

    return $self;

}

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    $self->validator->(@_);

}

1;
