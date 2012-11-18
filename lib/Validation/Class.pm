# ABSTRACT: Data Validation Framework

package Validation::Class;

# VERSION

use Module::Find;

use Validation::Class::Core '!has';
use Module::Runtime 'use_module';
use Hash::Merge 'merge';
use Exporter ();

use Validation::Class::Prototype;

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

{

    sub return_class_proto {

        my $class = shift || caller(2);

        return vc_prototypes->get($class) || do {

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
            vc_prototypes->add($class => $proto);

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

}

sub import {

    my $caller = caller(0) || caller(1);

    strict->import;
    warnings->import;

    __PACKAGE__->export_to_level(1, @_);

    return_class_proto $caller # provision prototype when used

}

sub initialize_validator {

    my $self   = shift;

    my $proto  = return_class_proto ref $self || $self;

    my $arguments = $proto->build_args(@_);

    # provision a validation class configuration

    $proto->snapshot;

    # override prototype attibutes if requested

    if (defined($arguments->{fields})) {
        my $fields = delete $arguments->{fields};
        $proto->fields->clear->add($fields);
    }

    if (defined($arguments->{params})) {
        my $params = delete $arguments->{params};
        $proto->params->clear->add($params);
    }

    # process attribute assignments

    while (my($name, $value) = each (%{$arguments})) {

        my $ok = 0;

        $ok++ if $proto->fields->has($name);
        $ok++ if $proto->attributes->has($name);
        $ok++ if grep { $name eq $_ } ($proto->proxy_methods);

        $self->$name($value) if $self->can($name) && $ok;

    }

    # process plugins

    foreach my $plugin ($proto->plugins->keys) {

        $proto->plugins->add($plugin => $plugin->new($proto))
            if $plugin->can('new')
        ;

    }

    # process builders

    foreach my $builder ($proto->builders->list) {

        $builder->($self, $arguments);

    }

    # initialize prototype

    $proto->normalize;

    # ready-set-go !!!

    return $self;

}

=head1 SYNOPSIS

    package MyApp::User;

    use Validation::Class;

    mixin basic     => {
        required    => 1,
        max_length  => 255,
        filters     => [qw/trim strip/]
    };

    field login     => {
        mixin       => 'basic',
        min_length  => 5
    };

    field password  => {
        mixin       => 'basic',
        min_length  => 5,
        min_symbols => 1
    };

    package main;

    my $user = MyApp::User->new(login => 'admin', password => 'secr3t');

    unless ($user->validate('login', 'password')) {

        # do something with the errors
        # e.g. print $user->errors_to_string

        # or   my @errors     = $user->get_errors
        # or   my $has_errors = $user->error_count

        # etc ...

    }

    1;

=head1 DESCRIPTION

Validation::Class is a robust data validation framework which aims to provide
the building blocks for easily definable self-validating classes.

Validation::Class provides a light-weight object system, self-validating
sub-routines, validation profiles, compartmentalization, input filtering,
extensibility (create your own custom validators and input filters), class
inheritance, automatic array handling, and much more.

If you are new to Validation::Class, or would like more information on the
underpinnings of this library and how it views and approaches data validation,
please review L<Validation::Class::Manual::Intro>.

=cut

=keyword attribute

The attribute keyword (or has) creates a class attribute. This is only a
minimalistic variant of what you may have encountered in other object systems.

    package MyApp::User;

    use Validate::Class;

    attribute 'bothered' => 1;

    attribute 'attitude' => sub {

        return $self->bothered ? 1 : 0

    };

    1;

The attribute keyword takes two arguments, the attribute name and a constant or
coderef that will be used as its default value.

=cut

sub has { goto &attribute }
sub attribute {

    my $package = shift if @_ == 3;

    my ($attributes, $default) = @_;

    return unless $attributes;

    $attributes = [$attributes] unless ref $attributes eq 'ARRAY';

    for my $attribute (@$attributes) {

        return configure_class_proto $package => sub {

            my ($proto) = @_;

            $proto->register_attribute($attribute => $default);

            return $proto;

        };

    }

}

=keyword build

The build keyword (or bld) registers a coderef to be run at instantiation much
in the same way the common L<Moose> BUILD routine is used.

    package MyApp::User;

    use Validation::Class;

    build sub {

        my ($self, $args) = @_;

    };

The build keyword takes one argument, a coderef which is passed the instantiated
class object.

=cut

sub bld { goto &build }
sub build {

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

The directive keyword (or dir) creates custom validator directives to be used in
your field definitions. It is a means of extending the pre-existing directives
table before runtime and is ideal for creating custom directive extension
packages to be used in all your classes.

    directive 'is_email' => sub {

        my ($directive_value, $parameter_value, $field_object) = @_;

        my $validator = Data::Validate::Email->new;

        unless ($validator->is_email($parameter_value)) {

            my $handle = $field_object->label || $field_object->name;

            $field_object->errors->add("$handle must be a valid email address");

            return 0;

        }

        return 1;

    };

    1;

The directive keyword takes two arguments, the name of the directive and a
coderef which will be used to validate the associated field. The coderef is
passed four ordered parameters, the value of directive, the value of the
field (parameter value), the field object (hashref), and the instantiated class
object. The validator MUST return true or false.

Additionally, if you only desire to extend the list of acceptable directives,
you can create a no-op by simply returning true, e.g.:

    directive 'new_addition' => sub {1};

=cut

sub dir { goto &directive }
sub directive {

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

The field keyword (or fld) creates a data validation rule for reuse and validation
in code. The field name should correspond with the parameter name expected to
be passed to your validation class.

    package MyApp::User;

    use Validation::Class;

    field 'login' => {
        required   => 1,
        min_length => 1,
        max_length => 255,
        ...
    };

The field keyword takes two arguments, the field name and a hashref of
key/values pairs known as directives.

The field keyword also creates accessors which provide easy access to the
field's corresponding parameter value(s). Accessors will be created using the
field's name as a label having any special characters replaced with an
underscore.

    field 'login' => {
        required   => 1,
        min_length => 1,
        max_length => 255,
        ...
    };

    field 'preference.send_reminders' => {
        required   => 1,
        max_length => 1,
        ...
    };

    my $value = $self->login;

    $self->login($new_value);

    $self->preference_send_reminders;

Protip: Field directives are used to validate scalar and array data. Don't use
fields to store and validate objects. Please see the *has* keyword instead or
use an object system with type constraints like L<Moose>.

=cut

sub fld { goto &field }
sub field {

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

The filter keyword (or flt) creates custom filters to be used in your field
definitions. It is a means of extending the pre-existing filters table before
runtime and is ideal for creating custom directive extension packages to be used
in all your classes.

    package MyApp::Directives;

    use Validation::Class;

    filter 'flatten' => sub {

        $_[0] =~ s/[\t\r\n]+/ /g;
        $_[0] # return

    };

    package MyApp::User;

    use Validate::Class;
    use MyApp::Directives;

    field 'description' => {
        filters => ['trim', 'flatten'],
        ...
    };

    1;

The filter keyword takes two arguments, the name of the filter and a
coderef which will be used to filter the value the associated field. The coderef
is passed the value of the field and that value MUST be operated on directly.
The coderef should also return the transformed value.

=cut

sub flt { goto &filter }
sub filter {

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

The load keyword (or set), which can also be used as a method, provides options
for extending the current class by attaching other L<Validation::Class> classes
as relatives, roles, plugins, etc. The process of applying roles to the current
class mainly involve copying the role's methods and configuration.

NOTE: While the load/set functionality is not depreciated and will remain part
of this library, its uses are no longer recommended as there are better ways to
achieve the desired results. Additionally, the following usage scenarios can be
refactored using traditional inheritance.

    package MyApp;

    use Validation::Class;

    # load stuff (extend MyApp)

    load {

        # run package commands

    };

    1;

The C<load.classes> option, can be a constant or arrayref and uses L<Module::Find>
to load B<all> child classes (in-all-subdirectories) for convenient access
through the class() method. Existing parameters and configuration options are
passed to the child class' constructor. All attributes can be easily overwritten
using the attribute's accessors on the child class. These child classes are
often referred to as relatives. This option accepts a constant or an arrayref of
constants.

    package MyApp;

    use Validation::Class;

    # load all child classes

    load {
        classes => [
            __PACKAGE__
        ]
    };

    package main;

    my $app = MyApp->new;

    my $rel = $app->class('relative'); # new MyApp::Relative object

    my $rel = $app->class('data_source'); # MyApp::DataSource
    my $rel = $app->class('datasource-first'); # MyApp::Datasource::First

    1;

The C<load.plugins> option is used to load plugins that support Validation::Class.
A Validation::Class plugin is little more than a class that implements a "new"
method that extends the associated validation class object. As usual, an official
Validation::Class plugin can be referred to using shorthand while custom plugins
are called by prefixing a plus symbol to the fully-qualified plugin name. Learn
more about plugins at L<Validation::Class::Intro>. This option accepts a
constant or an arrayref of constants.

    package MyVal;

    use Validation::Class;

    load {
        plugins => [
            'CPANPlugin', # Validation::Class::Plugin::CPANPlugin
            '+MyVal::Plugin'
        ]
    };

    1;

The C<load.roles> option is used to load and inherit functionality from child
classes, these classes should be used and thought-of as roles. Any validation
class can be used as a role with this option. This option accepts a constant or
an arrayref of constants.

    package MyVal::User;

    use Validation::Class;

    load {
        roles => [
            'MyVal::Person'
        ]
    };

    1;

Purely for the sake of aesthetics we have designed an alternate syntax for
executing load/set commands, the syntax is as follows:

    package MyVal::User;

    use Validation::Class;

    load roles => ['MyVal::Person'];
    load classes => [__PACKAGE__];
    load plugins => [
        'CPANPlugin', # Validation::Class::Plugin::CPANPlugin
        '+MyVal::Plugin'
    ];

=cut

sub set { goto &load }
sub load {

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

=keyword method

The method keyword (or mth) is used to create an auto-validating method. Similar
to method signatures, an auto-validating method can leverage pre-existing
validation rules and profiles to ensure a method has the required data necessary
to proceed.

    package MyApp::User;

    use Validation::Class;

    method 'register' => {

        input  => ['name', '+email', 'login', '+password'],
        output => ['+id'], # optional output validation, dies on failure
        using  => sub {

            my ($self, @args) = @_;

            # .... do something registrationy

            $self->id(...); # set the ID field for output validation

            return $self;

        }

    };

    package main;

    my $user = MyApp::User->new(params => $params);

    if ($user->register) {
        ...
    }

    1;

The method keyword takes two arguments, the name of the method to be created
and a hashref of required key/value pairs. The hashref must have an "input"
variable whose value is either an arrayref of fields to be validated,
or a constant value which matches a validation profile name. The hashref must
also have a "using" variable whose value is a coderef which will be executed upon
successfully validating the input. Whether and what the method returns is yours
to decide.

Optionally the required hashref can have an "output" variable whose value is
either an arrayref of fields to be validated, or a constant value which matches
a validation profile name which will be used to perform data validation B<after>
the coderef has been executed. Please note that output validation failure will
cause the program to die, the premise behind this decision is based on the
assumption that given successfully validated input a routine's output should be
predictable and if an error occurs it is most-likely a program error as opposed
to a user error.

See the ignore_failure and report_failure switch to control how method input
validation failures are handled.

=cut

sub mth { goto &method }
sub method {

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

The mixin keyword (or mxn) creates a validation rules template that can be
applied to any field using the mixin directive. Mixin directives are processed
first so existing field directives will override the mixed-in directives.

    package MyApp::User;

    use Validation::Class;

    mixin 'constrain' => {
        required   => 1,
        min_length => 1,
        max_length => 255,
        ...
    };

    # e.g.
    field 'login' => {
        mixin => 'constrain',
        ...
    };

The mixin keyword takes two arguments, the mixin name and a hashref of key/values
pairs known as directives.

=cut

sub mxn { goto &mixin }
sub mixin {

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
method should never be overridden. Use the build keyword to hooking into the
instantiation process.

    package MyApp;

    use Validation::Class;

    # optionally

    build sub {

        my ($self, @args) = @_; # is instantiated

    };

    package main;

    my $app = MyApp->new;

    ...

=cut

sub new {

    my $class = shift;

    my $proto = return_class_proto $class;

    my $self  = bless {},  $class;

    initialize_validator $self, @_;

    return $self;

}

=keyword profile

The profile keyword (or pro) stores a validation profile (coderef) which as in
the traditional use of the term is a sequence of validation routines that validate
data relevant to a specific action.

    package MyApp::User;

    use Validation::Class;

    profile 'signup' => sub {

        my ($self, @args) = @_;

        # ... do other stuff

        return $self->validate(qw(
            +name
            +email
            +email_confirmation
            -login
            +password
            +password_confirmation
        ));

    };

    package main;

    my $user = MyApp::User->new(params => $params);

    unless ($user->validate_profile('signup')) {

        die $user->errors_to_string;

    }

The profile keyword takes two arguments, a profile name and coderef which will
be used to execute a sequence of actions for validation purposes.

=cut

sub pro { goto &profile }
sub profile {

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
this method directly, see L<Validation::Class/"THE PROTOTYPE CLASS">.

    package MyApp;

    use Validation::Class;

    package main;

    my $app = MyApp->new;

    my $prototype = $app->prototype;

    ...

=cut

sub proto { goto &prototype }
sub prototype {

    my ($self) = pop @_;

    return_class_proto ref $self || $self;

}

=head1 SEE ALSO

Additionally you may want to look elsewhere for your data validation needs so
the following is a list of recommended validation libraries/frameworks you
might do well to look into.

L<Validate::Tiny> is nice for simple use-cases, it has virtually no dependencies
and solid test coverage. L<Data::Verifier> is a great approach towards adding
robust validation options to your existing Moose classes. Also, I have also
heard some good things about L<Data::FormValidator> as well.

=cut

1;
