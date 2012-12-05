# ABSTRACT: Simple Streaming Data Validation

package Validation::Class::Simple::Streamer;

use strict;
use warnings;
use Carp;

use overload
    bool     => \&validate,
    '""'     => \&messages,
    fallback => 1
;

use Validation::Class::Simple;
use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple::Streamer;

    my $params = Validation::Class::Simple::Streamer->new($parameters);

    $params->check($_)->filters('trim, strip') for qw(login password);

    unless ($params->check('email_address')->length(3)->email) {
        # validated login, password and email_address
    }

    unless ($params->check('home_phone')->telephone) {
        # validated login, password, email_address and home_phone
    }

    $params->check('password');

    # be as expressive as you like
    # validates login, password, email_address and home_phone
    ok() if
        $params->max_length(15) &&
        $params->min_symbols(1) &&
        $params->matches('password2')
    ;

    # are you of legal age?
    if ($params->check('user_age')->between('18-75')) {
        # access to explicit content approved
        # validated login, password, email_address, home_phone and user_age
    }

    # validate like a boss
    # THE END

=head1 DESCRIPTION

Validation::Class::Simple::Streamer is a simple streaming validation module
that makes data validation fun. It is built around the powerful
L<Validation::Class> data validation framework via L<Validation::Class::Simple>.

This module is/was inspired by the simplicity and expressiveness of the Node.js
validator library, L<https://github.com/chriso/node-validator>, but built on top
of the ever-awesome Validation::Class framework, which is designed to be modular
and extensible, i.e. whatever custom directives you create and install will
become methods on this class which you can then use to enforce policies.

=cut

sub new {

    my $class  = shift;
    my $params = $class->build_args(@_) || {};
    my $fields = { map { $_ => { name => $_ } } keys %{$params} };

    $class = ref $class || $class;

    my $self = {
        action => '',
        target => '',
        validator  => Validation::Class::Simple->new(
            params => $params,
            fields => $fields
        )
    };

    return bless $self, $class;

}

=method check

The check method specifies the parameter to be used in the following series of
commands.

    $self = $self->check('email_address');

=cut

sub check {

    my ($self, $target) = @_;

    if ($target) {

        my $validator = $self->{validator};

        $validator->fields->add($target => {name => $target})
            unless $validator->fields->has($target);

        $validator->queue($self->{target} = $target);

        $validator->proto->normalize;

    }

    return $self;

}

=method clear

The clear method resets the validation queue and declared fields but leaves the
declared parameters in-tact, almost like the object state post-instantiation.

    $self->clear;

=cut

sub clear {

    my ($self) = @_;

    $self->{validator}->proto->queued->clear;

    $self->{validator}->proto->reset_fields;

    return $self;

}

sub declare {

    my ($self, @config) = @_;

    my $arguments = pop(@config);
    my $action    = shift(@config) || $self->{action};

    my $target    = $self->{target};
    my $validator = $self->{validator};

    return $self unless $target;

    unless ($arguments) {
        $arguments = 1 if $action eq 'city';
        $arguments = 1 if $action eq 'creditcard';
        $arguments = 1 if $action eq 'date';
        $arguments = 1 if $action eq 'decimal';
        $arguments = 1 if $action eq 'email';
        $arguments = 1 if $action eq 'hostname';
        $arguments = 1 if $action eq 'multiples';
        $arguments = 1 if $action eq 'required';
        $arguments = 1 if $action eq 'ssn';
        $arguments = 1 if $action eq 'state';
        $arguments = 1 if $action eq 'telephone';
        $arguments = 1 if $action eq 'time';
        $arguments = 1 if $action eq 'uuid';
        $arguments = 1 if $action eq 'zipcode';
    }

    if ($validator->fields->has($target)) {

        my $field = $validator->fields->get($target);

        if ($field->can($action)) {

            $field->$action($arguments) if defined $arguments;

            return $self;

        }

    }

    exit carp sprintf q(Can't locate object method "%s" via package "%s"),
        $action, ((ref $_[0] || $_[0]) || 'main')
    ;

}

=method messages

The messages method returns any registered errors as a concatenated string using
the L<Validation::Class::Prototype/errors_to_string> method and accepts the same
parameters.

    print $self->messages("\n");

=cut

sub messages {

    my ($self, @arguments) = @_;

    return $self->{validator}->errors_to_string(@arguments);

}

=method params

The params method gives you access to the validator's params list which is a
L<Validation::Class::Mapping> object.

    $params = $self->params($parameters);

=cut

sub params {

    my ($self, @arguments) = @_;

    $self->{validator}->params->add(@arguments);

    return $self->{validator}->params;

}

=method validate

The validate method uses the validator to perform data validation based on
the series and sequence of commands issued previously. This method is called
implicitly whenever the object is used in boolean context, e.g. in a conditional.

    $true = $self->validate;

=cut

sub validate {

    my ($self) = @_;

    my $true = $self->{validator}->validate;

    $self->{validator}->clear_queue if $true; # reduces validation overhead

    return $true;

}

=method validator

The validator method gives you access to the object's validation class which is
a L<Validation::Class::Simple> object.

    $validator = $self->validator;

=cut

sub validator {

    my ($self) = @_;

    return $self->{validator};

}

sub AUTOLOAD {

    (my $routine = $Validation::Class::Simple::Streamer::AUTOLOAD) =~ s/.*:://;

    my ($self) = @_;

    if ($routine) {

        $self->{action} = $routine;

        goto &declare;

    }

    exit carp sprintf q(Can't locate object method "%s" via package "%s"),
        $routine, ((ref $_[0] || $_[0]) || 'main')
    ;

}

sub DESTROY;

1;
