# Base Class for Validation Class Directives

package Validation::Class::Directive;

use strict;
use warnings;

use Validation::Class::Core;

use Carp 'confess';

# VERSION

=head1 SYNOPSIS

    package Validation::Class::Plugin::Blacklist;

    use base 'Validation::Class::Directive';
    use Validation::Class::Core;

    has 'mixin'     => 0;
    has 'field'     => 1;
    has 'multi'     => 0;
    has 'message'   => '%s has been blacklisted';

    sub validate {

        my $self = shift;

        my ($proto, $field, $param) = @_;

        if (defined $field->{blacklist} && $param) {

            # is the parameter value blacklisted?
            my @blacklist = read_file('/blacklist.txt');

            $self->error if grep { $param =~ /^$_$/ } @blacklist;

        }

    }

    1;

... in your validation class:

    package MyApp::Person;

    use Validation::Class;

    field user_ip => {
        label => 'User IP Address',
        required  => 1,
        blacklist => 1
    };

    1;

... in your application:

    package main;

    use MyApp::Person;

    my $person = MyApp::Person->new(ip_address => '0.0.0.0');

    unless ($person->validates) {
        # handle validation error
    }

=head1 DESCRIPTION

Validation::Class::Directive provides a base-class for validation class
directives.

=cut

# defaults

has 'mixin'         => 0;
has 'field'         => 0;
has 'multi'         => 0;
has 'message'       => '%s was not processed successfully';
has 'validator'     => sub { sub{1} };
has 'dependencies'  => sub {{ normalization => [], validation => [] }};
has 'name'          => sub {

    my ($self) = @_;

    my $name = ref $self || $self;

    my $regexp = qr/Validation::Class::Directive::(.*)$/;

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

    # use custom field-level error message
    if ($field->error) {
        $field->errors->add($field->error);
    }

    # use field-level error message override
    elsif (defined $field->{messages} && $field->{messages}->{$self->name}) {
        my $message = $field->{messages}->{$self->name};
        $field->errors->add(sprintf($message, @tokens));
    }

    # use class-level error message override
    elsif ($proto->messages->has($self->name)) {
        my $message = $proto->messages->get($self->name);
        $field->errors->add(sprintf($message, @tokens));
    }

    # use directive error message
    else {
        $field->errors->add(sprintf($self->message, @tokens));
    }

    return $self;

}

sub validate {

    my $self = shift;

    my ($proto, $field, $param) = @_;

    my $context = $proto->stash->{'validation.context'};

    # nasty hack, we need a better way !!!
    $self->validator->($context, $field, $proto->params);

    return $self;

}

1;
