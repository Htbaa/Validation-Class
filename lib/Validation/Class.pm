# ABSTRACT: Powerful Data Validation Framework

package Validation::Class;

use strict;
use warnings;

use Module::Find;

use Validation::Class::Util '!has';
use Module::Runtime 'use_module';
use Hash::Merge 'merge';
use Clone 'clone';
use Exporter ();

use Validation::Class::Prototype;

# VERSION

our @ISA    = qw(Exporter);
our @EXPORT = qw(

    attribute
    bld
    build
    dir
    directive
    fld
    field
    flt
    filter
    has
    load
    msg
    message
    mth
    method
    mxn
    mixin
    obj
    object
    pro
    profile
    set

);

sub return_class_proto {

    my $class = shift || caller(2);

    return prototype_registry->get($class) || do {

        # build new prototype class

        my $proto = Validation::Class::Prototype->new(
            package => $class
        );

        no strict 'refs';
        no warnings 'redefine';

        # respect foreign constructors (such as $class->new) if found

        my $new = $class->can("new") ?
            "initialize_validator" : "new"
        ;

        # injected into every derived class (override if necessary)

        *{"$class\::$new"}      = sub { goto \&$new };
        *{"$class\::proto"}     = sub { goto \&prototype };
        *{"$class\::prototype"} = sub { goto \&prototype };

        # inject prototype class aliases unless exist

        my @aliases = $proto->proxy_methods;

        foreach my $alias (@aliases) {

            next if $class->can($alias);

            # slight-of-hand

            $proto->set_method($alias, sub {

                shift @_;

                $proto->$alias(@_);

            });

        }

        # inject wrapped prototype class aliases unless exist

        my @wrapped_aliases = $proto->proxy_methods_wrapped;

        foreach my $alias (@wrapped_aliases) {

            next if $class->can($alias);

            # slight-of-hand

            $proto->set_method($alias, sub {

                my $self = shift @_;

                $proto->$alias($self, @_);

            });

        }

        # cache prototype
        prototype_registry->add($class => $proto);

        $proto; # return-once

    };

}

sub configure_class_proto {

    my $configuration_routine = pop;

    return unless "CODE" eq ref $configuration_routine;

    no strict 'refs';

    my $proto = return_class_proto shift;

    $configuration_routine->($proto);

    return $proto;

}

sub import {

    my $caller = caller(0) || caller(1);

    strict->import;
    warnings->import;

    __PACKAGE__->export_to_level(1, @_);

    return return_class_proto $caller # provision prototype when used

}

sub initialize_validator {

    my $self   = shift;
    my $proto  = $self->prototype;

    my $arguments = $proto->build_args(@_);

    # provision a validation class configuration

    $proto->snapshot;

    # override prototype attributes if requested

    if (defined($arguments->{fields})) {
        my $fields = delete $arguments->{fields};
        $proto->fields->clear->add($fields);
    }

    if (defined($arguments->{params})) {
        my $params = delete $arguments->{params};
        $proto->params->clear->add(clone $params);
    }

    # process attribute assignments

    while (my($name, $value) = each (%{$arguments})) {

        my $ok = 0;

        $ok++ if $proto->fields->has($name);
        $ok++ if $proto->attributes->has($name);
        $ok++ if grep { $name eq $_ } ($proto->proxy_methods);

        $self->$name($value) if $self->can($name) && $ok;

    }

    # process builders

    foreach my $builder ($proto->builders->list) {

        $builder->($self, $arguments);

    }

    # initialize prototype

    $proto->normalize;

    # process plugins

    foreach my $plugin ($proto->plugins->keys) {

        $proto->plugins->add($plugin => $plugin->new($proto))
            if $plugin->can('new')
        ;

    }

    # ready-set-go !!!

    return $self;

}

=head1 SYNOPSIS

    use Validation::Class::Simple::Streamer;

    my $input = Validation::Class::Simple::Streamer->new($params);

    $input->check($_)->required->length('5-255')->filters([qw/trim strip/])
        for qw/username password/
    ;

    $input->check('password')->min_symbols(1);

    unless ($input) {
        # handle the failures
    }

=head1 DESCRIPTION

Validation::Class is a scalable data validation library with interfaces for
applications of all sizes. L<Validation::Class::Simple::Streamer> is a great way
to leverage this library for ad-hoc use-cases, L<Validation::Class::Simple>
is very well suited for applications of moderate sophistication where it makes
sense to pre-declared validation rules, and Validation::Class is designed to
transform class namespaces into data validation domains where consistency and
reuse are primary concerns.

Validation::Class provides an extensible framework for defining reusable data
validation rules. It ships with a complete set of pre-defined validations and
filters referred to as L<"directives"|Validation::Class::Directives/DIRECTIVES>.

The core feature-set consist of self-validating methods, validation profiles,
reusable validation rules and templates, pre and post input filtering, class
inheritance, automatic array handling, and extensibility (e.g. overriding
default error messages, creating custom validators, creating custom input
filters and much more).

Validation::Class promotes DRY (don't repeat yourself) code. The main benefit in
using Validation::Class is that the architecture is designed to increase the
consistency of data input handling. The following is a more traditional usage
of Validation::Class:

    package MyApp::Person;

    use Validation::Class;

    # data validation template
    mixin basic     => {
        required    => 1,
        max_length  => 255,
        filters     => [qw/trim strip/]
    };

    # data validation rule for the username parameter
    field username  => {
        mixin       => 'basic',
        min_length  => 5
    };

    # data validation rule for the password parameter
    field password  => {
        mixin       => 'basic',
        min_length  => 5,
        min_symbols => 1
    };

    # elsewhere in your application
    my $person = MyApp::Person->new(username => 'admin', password => 'secr3t');

    # validate rules on the person object
    unless ($person->validates) {
        # handle the failures
    }

    1;

=head1 QUICKSTART

If you are looking for a simple in-line data validation module built using the
same tenets and principles as Validation::Class, please review
L<Validation::Class::Simple>.

=head1 RATIONALE

If you are new to Validation::Class, or would like more information on the
underpinnings of this library and how it views and approaches data validation,
please review L<Validation::Class::Whitepaper>.

=cut

=keyword attribute

The attribute keyword (or has) registers a class attribute. This is only a
minimalistic variant of what you may have encountered in other object systems.

    package MyApp::Person;

    use Validate::Class;

    attribute 'first_name' => 'Peter';
    attribute 'last_name'  => 'Venkman';
    attribute 'full_name'  => sub {

        my ($self) = @_;

        return join ', ', $self->last_name, $self->first_name;

    };

    1;

The attribute keyword takes two arguments, the attribute name and a constant or
coderef that will be used as its default value.

=cut

sub has { goto &attribute } sub attribute {

    my $package = shift if @_ == 3;

    my ($attributes, $default) = @_;

    return unless $attributes;

    $attributes = [$attributes] unless ref $attributes eq 'ARRAY';

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_attribute($_ => $default) for @$attributes;

        return $proto;

    };

}

=keyword build

The build keyword (or bld) registers a coderef to be run at instantiation much
in the same way the common BUILD routine is used in modern OO frameworks.

    package MyApp::Person;

    use Validation::Class;

    build sub {

        my ($self, $args) = @_;

        # run after instantiation in the order declared

    };

The build keyword takes one argument, a coderef which is passed the instantiated
class object.

=cut

sub bld { goto &build } sub build {

    my $package = shift if @_ == 2;

    my ($code) = @_;

    return unless ("CODE" eq ref $code);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_builder($code);

        return $proto;

    };

}

=keyword directive

The directive keyword (or dir) registers custom validator directives to be used
in your field definitions. This is a means of extending the list of directives
per instance. See the list of core directives, L<Validation::Class::Directives>,
or review L<Validation::Class::Directive> for insight into creating your own
CPAN installable directives.

    package MyApp::Directives;

    use Validation::Class 'directive';

    use Data::Validate::Email;

    directive 'isa_email_address' => sub {

        my ($self, $proto, $field, $param) = @_;

        my $validator = Data::Validate::Email->new;

        unless ($validator->is_email($param)) {

            my $handle = $field->label || $field->name;

            $field->errors->add("$handle must be a valid email address");

            return 0;

        }

        return 1;

    };

    package MyApp::Person;

    use Validate::Class;

    use MyApp::Directives;

    field 'email_address' => {
        isa_email_address => 1
    };

    1;

The directive keyword takes two arguments, the name of the directive and a
coderef which will be used to validate the associated field. The coderef is
passed four ordered parameters; a directive object, the class prototype object,
the current field object, and the matching parameter's value. The validator
(coderef) is evaluated by its return value as well as whether it altered any
error containers.

=cut

sub dir { goto &directive } sub directive {

    my $package = shift if @_ == 3;

    my ($name, $code) = @_;

    return unless ($name && $code);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_directive($name, $code);

        return $proto;

    };

}

=keyword field

The field keyword (or fld) registers a data validation rule for reuse and
validation in code. The field name should correspond with the parameter name
expected to be passed to your validation class or validated against.

    package MyApp::Person;

    use Validation::Class;

    field 'username' => {
        required   => 1,
        min_length => 1,
        max_length => 255
    };

The field keyword takes two arguments, the field name and a hashref of key/values
pairs known as directives. For more information on pre-defined directives, please
review the L<"list of core directives"|Validation::Class::Directives/DIRECTIVES>.

The field keyword also creates accessors which provide easy access to the
field's corresponding parameter value(s). Accessors will be created using the
field's name as a label having any special characters replaced with an
underscore.

    field 'send-reminders' => { # accessor will be created as send_reminders
        length   => 1
    };

Protip: Field directives are used to validate scalar and array data. Don't use
fields to store and validate objects. Please see the *has* keyword instead or
use an object system with type constraints like L<Moose>.

=cut

sub fld { goto &field } sub field {

    my $package = shift if @_ == 3;

    my ($name, $data) = @_;

    return unless ($name && $data);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_field($name, $data);

        return $proto;

    };

}

=keyword filter

The filter keyword (or flt) registers custom filters to be used in your field
definitions. It is a means of extending the pre-existing filters declared by
the L<"filters directive"|Validation::Class::Directive::Filters> before
instantiation.

    package MyApp::Directives;

    use Validation::Class;

    filter 'flatten' => sub {

        $_[0] =~ s/[\t\r\n]+/ /g;
        return $_[0];

    };

    package MyApp::Person;

    use Validate::Class;

    use MyApp::Directives;

    field 'biography' => {
        filters => ['trim', 'flatten']
    };

    1;

The filter keyword takes two arguments, the name of the filter and a
coderef which will be used to filter the value the associated field. The coderef
is passed the value of the field and that value MUST be operated on directly.
The coderef should also return the transformed value.

=cut

sub flt { goto &filter } sub filter {

    my $package = shift if @_ == 3;

    my ($name, $code) = @_;

    return unless ($name && $code);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_filter($name, $code);

        return $proto;

    };

}

=keyword load

The load keyword (or set), which can also be used as a class method, provides
options for extending the current class by declaring roles, plugins, etc.

The process of applying roles to the current class mainly involves copying the
subject's methods and prototype configuration.

    package MyApp::Person;

    use Validation::Class;

    load role => 'MyApp::User';

    1;

The `classes` (or class) option, can be a constant or arrayref and uses
L<Module::Find> to load all child classes (in-all-subdirectories) for convenient
access through the L<Validation::Class::Prototype/class> method.

Existing parameters and configuration options are passed to the child class
constructor. All attributes can be easily overwritten using the attribute's
accessors on the child class. These child classes are often referred to as
relatives. This option accepts a constant or an arrayref of constants.

    package MyApp;

    use Validation::Class;

    # load all child classes
    load classes => [__PACKAGE__];

    package main;

    my $app = MyApp->new;

    my $person = $app->class('person'); # return a new MyApp::Person object

    1;

The `roles` (or role) option is used to load and inherit functionality from
other validation classes. These classes should be used and thought-of as roles
although they can also be fully-functioning validation classes. This option
accepts a constant or an arrayref of constants.

    package MyApp::Person;

    use Validation::Class;

    load roles => ['MyApp::User', 'MyApp::Visitor'];

    1;

=cut

sub set { goto &load } sub load {

    my $package;
    my $data;

    # handle different types of invocations

    # 1   - load({})
    # 2+  - load(a => b)
    # 2+  - package->load({})
    # 3+  - package->load(a => b)

    # --

    # load({})

    if (@_ == 1) {

        if ("HASH" eq ref $_[0]) {

            $data = shift;

        }

    }

    # load(a => b)
    # package->load({})

    elsif (@_ == 2) {

        if ("HASH" eq ref $_[-1]) {

            $package = shift;
            $data    = shift;

        }

        else {

            $data = {@_};

        }

    }

    # load(a => b)
    # package->load(a => b)

    elsif (@_ >= 3) {

        if (@_ % 2) {

            $package = shift;
            $data    = {@_};

        }

        else {

            $data = {@_};

        }

    }

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_settings($data);

        return $proto;

    };

}

=keyword message

The message keyword (or msg) registers a class-level error message template that
will be used in place of the error message defined in the corresponding directive
class if defined. Error messages can also be overridden at the individual
field-level as well. See the L<Validation::Class::Directive::Messages> for
instructions on how to override error messages at the field-level.

    package MyApp::Person;

    use Validation::Class;

    field email_address => {
        required   => 1,
        min_length => 3,
        messages   => {
            # field-level error message override
            min_length => '%s is not even close to being a valid email address'
        }
    };

    # class-level error message overrides
    message required   => '%s is needed to proceed';
    message min_length => '%s needs more characters';

    1;

The message keyword takes two arguments, the name of the directive whose error
message you wish to override and a string which will be used to as a template
which is feed to sprintf to format the message.

=cut

sub msg { goto &message } sub message {

    my $package = shift if @_ == 3;

    my ($name, $template) = @_;

    return unless ($name && $template);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_message($name, $template);

        return $proto;

    };

}

=keyword method

The method keyword (or mth) is used to register an auto-validating method.
Similar to method signatures, an auto-validating method can leverage pre-existing
validation rules and profiles to ensure a method has the required data necessary
for execution.

    package MyApp::Person;

    use Validation::Class;

    method 'register' => {

        input  => ['name', '+email', 'username', '+password', '+password2'],
        output => ['+id'], # optional output validation, dies on failure
        using  => sub {

            my ($self, @args) = @_;

            # do something registrationy

            $self->id(...); # set the ID field for output validation

            return $self;

        }

    };

    package main;

    my $person = MyApp::Person->new(params => $params);

    if ($person->register) {

        # handle the successful registration

    }

    1;

The method keyword takes two arguments, the name of the method to be created
and a hashref of required key/value pairs. The hashref must have an `input`
key whose value is either an arrayref of fields to be validated, or a scalar
value which matches (a validation profile or auto-validating method name). The
hashref must also have a `using` key whose value is a coderef which will be
executed upon successfully validating the input. The `using` key/coderef can be
omitted when a sub-routine of the same name prefixed with an underscore is
present. Whether and what the method returns is yours to decide. The method will
return 0 if validation fails.

Optionally the required hashref can have an `output` key whose value is either
an arrayref of fields to be validated, or a scalar value which matches
(a validation profile or auto-validating method name) which will be used to
perform data validation B<after> the aforementioned coderef has been executed.

Please note that output validation failure will cause the program to die,
the premise behind this decision is based on the assumption that given
successfully validated input a routine's output should be predictable and if an
error occurs it is most-likely a program error as opposed to a user error.

See the ignore_failure and report_failure attributes on the prototype to control
how method input validation failures are handled.

=cut

sub mth { goto &method } sub method {

    my $package = shift if @_ == 3;

    my ($name, $data) = @_;

    return unless ($name && $data);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_method($name, $data);

        return $proto;

    };

}

=keyword mixin

The mixin keyword (or mxn) registers a validation rule template that can be
applied (or "mixed-in") to any field by specifying the mixin directive. Mixin
directives are processed first so existing field directives will override any
directives created by the mixin directive.

    package MyApp::Person;

    use Validation::Class;

    mixin 'boilerplate' => {
        required   => 1,
        min_length => 1,
        max_length => 255
    };

    field 'username' => {
        # min_length, max_length, but not required
        mixin    => 'boilerplate',
        required => 0
    };

The mixin keyword takes two arguments, the mixin name and a hashref of key/values
pairs known as directives.

=cut

sub mxn { goto &mixin } sub mixin {

    my $package = shift if @_ == 3;

    my ($name, $data) = @_;

    return unless ($name && $data);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_mixin($name, $data);

        return $proto;

    };

}

=method new

The new method instantiates a new class object, it performs a series of actions
(magic) required for the class function properly, and for that reason, this
method should never be overridden. Use the build keyword for hooking into the
instantiation process.

In the event a foreign `new` method is detected, an `initialize_validator`
method will be injected into the class containing the code (magic) necessary to
normalize your environment.

    package MyApp::Person;

    use Validation::Class;

    # hook
    build sub {

        my ($self, @args) = @_; # on instantiation

    };

    sub new {

        # rolled my own
        my $self = bless {}, shift;

        # execute magic
        $self->initialize_validator;

    }

=cut

sub new {

    my $class = shift;

    my $proto = return_class_proto $class;

    my $self  = bless {},  $class;

    initialize_validator $self, @_;

    return $self;

}

=keyword profile

The profile keyword (or pro) registers a validation profile (coderef) which as
in the traditional use of the term is a sequence of validation routines that
validates data relevant to a specific action.

    package MyApp::Person;

    use Validation::Class;

    profile 'check_email' => sub {

        my ($self, @args) = @_;

        if ($self->email_exists) {
            my $email = $self->fields->get('email');
            $email->errors->add('Email already exists');
            return 0;
        }

        return 1;

    };

    package main;

    my $user = MyApp::Person->new(params => $params);

    unless ($user->validate_profile('check_email')) {
        # handle failures
    }

The profile keyword takes two arguments, a profile name and coderef which will
be used to execute a sequence of actions for validation purposes.

=cut

sub pro { goto &profile } sub profile {

    my $package = shift if @_ == 3;

    my ($name, $code) = @_;

    return unless ($name && $code);

    return configure_class_proto $package => sub {

        my ($proto) = @_;

        $proto->register_profile($name, $code);

        return $proto;

    };

}

=method prototype

The prototype method (or proto) returns an instance of the associated class
prototype. The class prototype is responsible for manipulating and validating
the data model (the class). It is not likely that you'll need to access
this method directly, see L<Validation::Class::Prototype>.

    package MyApp::Person;

    use Validation::Class;

    package main;

    my $person = MyApp::Person->new;

    my $prototype = $person->prototype;

=cut

sub proto { goto &prototype } sub prototype {

    my ($self) = pop @_;

    return return_class_proto ref $self || $self;

}

=head1 PROXY METHODS

Validation::Class mostly provides sugar functions for modeling your data
validation requirements. Each class you create is associated with a *prototype*
class which provides the data validation engine and keeps your class namespace
free from pollution, please see L<Validation::Class::Prototype> for more
information on specific methods and attributes.

Validation::Class injects a few proxy methods into your class which are
basically aliases to the corresponding prototype class methods, however it is
possible to access the prototype directly using the proto/prototype methods.

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

head2 errors_to_string

    $self->errors_to_string;

See L<Validation::Class::Prototype/errors_to_string> for full
documentation.

=proxy_method get_errors

    $self->get_errors;

See L<Validation::Class::Prototype/get_errors> for full documentation.

=proxy_method get_fields

    $self->get_fields;

See L<Validation::Class::Prototype/get_fields> for full documentation.

=proxy_method get_params

    $self->get_params;

See L<Validation::Class::Prototype/get_params> for full documentation.

=proxy_method fields

    $self->fields;

See L<Validation::Class::Prototype/fields> for full documentation.

=proxy_method filtering

    $self->filtering;

See L<Validation::Class::Prototype/filtering> for full documentation.

=proxy_method ignore_failure

    $self->ignore_failure;

See L<Validation::Class::Prototype/ignore_failure> for full
documentation.

=proxy_method ignore_unknown

    $self->ignore_unknown;

See L<Validation::Class::Prototype/ignore_unknown> for full
documentation.

=proxy_method param

    $self->param;

See L<Validation::Class::Prototype/param> for full documentation.

=proxy_method params

    $self->params;

See L<Validation::Class::Prototype/params> for full documentation.

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

=head1 EXTENSIBILITY

Validation::Class does NOT provide method modifiers but can be easily extended
with L<Class::Method::Modifiers>.

=head2 before

    before foo => sub { ... };

See L<< Class::Method::Modifiers/before method(s) => sub { ... } >> for full
documentation.

=head2 around

    around foo => sub { ... };

See L<< Class::Method::Modifiers/around method(s) => sub { ... } >> for full
documentation.

=head2 after

    after foo => sub { ... };

See L<< Class::Method::Modifiers/after method(s) => sub { ... } >> for full
documentation.

=head1 SEE ALSO

B<If you have simple data validation needs, please review:>

=over

=item L<Validation::Class::Simple>

=back

Validation::Class validates strings, not structures. If you need a means for
validating object types you should be using a modern object system like L<Mo>,
L<Moo>, L<Mouse>, or L<Moose>. Alternatively you could use L<Params::Validate>.

In the event that you would like to look elsewhere for your data validation
needs, the following is a list of other validation libraries/frameworks you
might be interested in. If I've missed a really cool new validation library
please let me know.

=over

=item L<HTML::FormHandler>

This library seems to be the defacto standard for designing Moose classes with
HTML-centric data validation rules.

=item L<Data::Verifier>

This library is a great approach towards adding robust validation logic to
your existing Moose-based codebase.

=item L<Validate::Tiny>

This library is nice for simple use-cases, it has virtually no dependencies
and solid test coverage.

=back

=cut

1;
