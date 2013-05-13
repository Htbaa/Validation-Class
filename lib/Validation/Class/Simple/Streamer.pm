# ABSTRACT: Simple Streaming Data Validation

package Validation::Class::Simple::Streamer;

use 5.10.0;
use strict;
use warnings;

use base 'Validation::Class::Simple';

use Carp;
use Validation::Class::Util;

use overload bool => \&validate, '""' => \&messages, fallback => 1;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Simple::Streamer;

    my $params = {
        credit_card   => '0000000000000000',
        email_address => 'root@localhost',

    };

    my $rules = Validation::Class::Simple::Streamer->new(params => $params);

    # the point here is expressiveness
    # directive methods auto-validate in boolean context !!!

    if (not $rules->check('credit_card')->creditcard(['visa', 'mastercard'])) {
        # credit card is invalid visa/mastercard
        warn $rules->errors_to_string;
    }

    if (not $rules->check('email_address')->min_length(3)->email) {
        # email address is invalid
        warn $rules->errors_to_string;
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
    my $fields = $rules->error_fields;

    # warn with errors if any
    warn $rules->errors_to_string unless $rules->validate;

=head1 DESCRIPTION

Validation::Class::Simple::Streamer is a simple streaming validation module
that makes data validation fun. Target parameters and attach matching fields
and directives to them by chaining together methods which represent
Validation::Class L<directives|Validation::Class::Directives/DIRECTIVES>. This
module is built around the powerful L<Validation::Class> data validation
framework via L<Validation::Class::Simple>. This module is a sub-class of and
derived from the L<Validation::Class::Simple> class.

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
       $class  = ref $class || $class;
    my $self   = $class->SUPER::new(@_);

    $self->{action} = '';
    $self->{target} = '';

    return $self;

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

        return $self if $target eq $self->{target};

        $self->prototype->fields->add($target => {name => $target})
            unless $self->prototype->fields->has($target);

        $self->prototype->queue($self->{target} = $target);
        $self->prototype->normalize($self);

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

    $self->prototype->queued->clear;

    $self->prototype->reset_fields;

    return $self;

}

sub declare {

    my ($self, @config) = @_;

    my $arguments = pop(@config);
    my $action    = shift(@config) || $self->{action};
    my $target    = $self->{target};

    return $self unless $target;

    $self->prototype->queue($target); # if clear() was called or check() wasn't

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

    if ($self->prototype->fields->has($target)) {

        my $field = $self->prototype->fields->get($target);

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

    print $self->messages;

=cut

sub messages {

    my ($self, @arguments) = @_;

    return $self->prototype->errors_to_string(@arguments);

}

=method validate

The validate method uses the validator to perform data validation based on the
series and sequence of commands issued previously. This method is called
implicitly whenever the object is used in boolean context, e.g. in a
conditional.

    $true = $self->validate;

=cut

sub validate {

    my ($self) = @_;

    my $true = $self->prototype->validate($self);

    $self->prototype->clear_queue if $true; # reduces validation overhead

    return $true;

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

=head1 PROXY METHODS

Each instance of Validation::Class::Simple::Streamer is injected with a few
proxy methods which are basically aliases to the corresponding prototype
class methods, however it is possible to access the prototype directly using
the proto/prototype methods.

=proxy_method class

    $self->class;

See L<Validation::Class::Prototype/class> for full documentation.

=proxy_method clear_queue

    $self->clear_queue;

See L<Validation::Class::Prototype/clear_queue> for full documentation.

=proxy_method error_count

    $self->error_count;

See L<Validation::Class::Prototype/error_count> for full documentation.

=proxy_method error_fields

    $self->error_fields;

See L<Validation::Class::Prototype/error_fields> for full documentation.

=proxy_method errors

    $self->errors;

See L<Validation::Class::Prototype/errors> for full documentation.

=proxy_method errors_to_string

    $self->errors_to_string;

See L<Validation::Class::Prototype/errors_to_string> for full documentation.

=proxy_method get_errors

    $self->get_errors;

See L<Validation::Class::Prototype/get_errors> for full documentation.

=proxy_method get_fields

    $self->get_fields;

See L<Validation::Class::Prototype/get_fields> for full documentation.

=proxy_method get_hash

    $self->get_hash;

See L<Validation::Class::Prototype/get_hash> for full documentation.

=proxy_method get_params

    $self->get_params;

See L<Validation::Class::Prototype/get_params> for full documentation.

=proxy_method get_values

    $self->get_values;

See L<Validation::Class::Prototype/get_values> for full documentation.

=proxy_method fields

    $self->fields;

See L<Validation::Class::Prototype/fields> for full documentation.

=proxy_method filtering

    $self->filtering;

See L<Validation::Class::Prototype/filtering> for full documentation.

=proxy_method ignore_failure

    $self->ignore_failure;

See L<Validation::Class::Prototype/ignore_failure> for full documentation.

=proxy_method ignore_unknown

    $self->ignore_unknown;

See L<Validation::Class::Prototype/ignore_unknown> for full documentation.

=proxy_method is_valid

    $self->is_valid;

See L<Validation::Class::Prototype/is_valid> for full documentation.

=proxy_method param

    $self->param;

See L<Validation::Class::Prototype/param> for full documentation.

=proxy_method params

    $self->params;

See L<Validation::Class::Prototype/params> for full documentation.

=proxy_method plugin

    $self->plugin;

See L<Validation::Class::Prototype/plugin> for full documentation.

=proxy_method queue

    $self->queue;

See L<Validation::Class::Prototype/queue> for full documentation.

=proxy_method report_failure

    $self->report_failure;

See L<Validation::Class::Prototype/report_failure> for full
documentation.

=proxy_method report_unknown

    $self->report_unknown;

See L<Validation::Class::Prototype/report_unknown> for full documentation.

=proxy_method reset_errors

    $self->reset_errors;

See L<Validation::Class::Prototype/reset_errors> for full documentation.

=proxy_method reset_fields

    $self->reset_fields;

See L<Validation::Class::Prototype/reset_fields> for full documentation.

=proxy_method reset_params

    $self->reset_params;

See L<Validation::Class::Prototype/reset_params> for full documentation.

=proxy_method set_errors

    $self->set_errors;

See L<Validation::Class::Prototype/set_errors> for full documentation.

=proxy_method set_fields

    $self->set_fields;

See L<Validation::Class::Prototype/set_fields> for full documentation.

=proxy_method set_params

    $self->set_params;

See L<Validation::Class::Prototype/set_params> for full documentation.

=proxy_method set_method

    $self->set_method;

See L<Validation::Class::Prototype/set_method> for full documentation.

=proxy_method stash

    $self->stash;

See L<Validation::Class::Prototype/stash> for full documentation.

=proxy_method validate

    $self->validate;

See L<Validation::Class::Prototype/validate> for full documentation.

=proxy_method validate_method

    $self->validate_method;

See L<Validation::Class::Prototype/validate_method> for full documentation.

=proxy_method validate_profile

    $self->validate_profile;

See L<Validation::Class::Prototype/validate_profile> for full documentation.

=cut

1;
