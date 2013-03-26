# ABSTRACT: Simple Streaming Data Validation

package Validation::Class::Simple::Streamer;

use strict;
use warnings;
use overload bool => \&validate, '""' => \&messages, fallback => 1;

use Carp;

use Validation::Class::Simple;
use Validation::Class::Util;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple::Streamer;

    my $parameters = {
        credit_card   => '0000000000000000',
        email_address => 'root@localhost',

    };

    my $rules = Validation::Class::Simple::Streamer->new($parameters);

    # the point here is expressiveness
    # directive methods auto-validate in boolean context !!!

    if (not $rules->check('credit_card')->creditcard(['visa', 'mastercard'])) {
        # credit card is invalid visa/mastercard
        warn $rules->messages;
    }

    if (not $rules->check('email_address')->min_length(3)->email) {
        # email address is invalid
        warn $rules->messages;
    }

    # prepare password for validation
    $rules->check('password');

    die "Password is not valid"
        unless $rules->min_symbols(1) && $rules->matches('password2');

    # are you of legal age?
    if ($rules->check('member_years_of_age')->between('18-75')) {
        # access to explicit content approved
    }

    # get all fields with errors
    my $fields = $rules->validator->error_fields;

    # warn with errors if any
    warn $rules->messages unless $rules->is_valid;

    # validate like a boss
    # THE END

=head1 DESCRIPTION

Validation::Class::Simple::Streamer is a simple streaming validation module
that makes data validation fun. Target parameters and attach matching fields
and directives to them by chaining together methods which represent
Validation::Class L<directives|Validation::Class::Directives/DIRECTIVES>. This
module is built around the powerful L<Validation::Class> data validation
framework via L<Validation::Class::Simple>. This module was inspired by the
simplicity and expressiveness of the Node.js validator library, but built on
top of the ever-awesome Validation::Class framework, which is designed to be
modular and extensible, i.e. whatever custom directives you create and install
will become methods on this class which you can then use to enforce policies.

=cut

=head1 RATIONALE

If you are new to Validation::Class, or would like more information on
the underpinnings of this library and how it views and approaches
data validation, please review L<Validation::Class::Whitepaper>.
Please review the L<Validation::Class::Simple/GUIDED-TOUR> for a detailed
step-by-step look into how Validation::Class works.

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

The check method specifies the parameter to be affected by directive methods
if/when called.

    $self = $self->check('email_address'); # focus on email_address

    $self->required;        # apply the Required directive to email_address
    $self->min_symbols(1);  # apply the MinSymbols directive to email_address
    $self->min_length(5);   # apply the MinLength directive to email_address

=cut

sub check {

    my ($self, $target) = @_;

    if ($target) {

        my $validator = $self->{validator};

        $validator->fields->add($target => {name => $target})
            unless $validator->fields->has($target);

        $validator->queue($self->{target} = $target);

        $validator->proto->normalize($validator);

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
a L<Validation::Class::Simple> object by default.

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

    croak sprintf q(Can't locate object method "%s" via package "%s"),
        $routine, ((ref $_[0] || $_[0]) || 'main')
    ;

}

sub DESTROY {}

1;
