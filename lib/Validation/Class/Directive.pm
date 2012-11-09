# ABSTRACT: Base Class for Validation Class Directives

package Validation::Class::Directive;

use Validation::Class::Core 'build_args', 'has';

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive;

    my $validator = Validation::Class::Directive->new(
        mixin     => 0,
        field     => 1,
        multi     => 0,
        validator => sub {

            my ($directive_value, $parameter_value, $field_object) = @_;

        }
    );

... written as a package

    package Validation::Class::Directive::FooBar;

    use base 'Validation::Class::Directive';
    use Validation::Class::Core;

    has 'mixin' => 0;
    has 'field' => 1;
    has 'multi' => 0;

    has 'validator' => sub {

    };

    1;

=head1 DESCRIPTION

Validation::Class::Directive provides a base-class for validation class
directives.

=cut

# defaults

has 'mixin'     => 0;
has 'field'     => 0;
has 'multi'     => 0;

has 'validator' => sub{1};

sub new {

    my $class = shift;

    my $arguments = $class->build_args(@_);

    my $self = bless {}, $class;

    while (my($key, $value) = each %{$arguments}) {
        $self->$key($value);
    }

    return $self;

}

sub name {

    my ($self) = @_;

    my $name = ref $self || $self;

    my $regexp = qr/V[^:]+::C[^:]+::D[^:]+::(.*)$/;

    ($name) = $name =~ $regexp;

    $name =~ s/([a-z])([A-Z])/$1_$2/g;
    $name =~ s/\W/_/g;
    $name = lc $name;

    return $name;

}

1;
