# ABSTRACT: Self-Validating Object System and Data Validation Framework

package Validation::Class;

use strict;
use warnings;

# VERSION

use Carp 'confess';
use Exporter ();
use Hash::Merge 'merge';
use Module::Find;
use Module::Runtime 'use_module';

use Validation::Class::Errors;
use Validation::Class::Field;
use Validation::Class::Fields;
use Validation::Class::Params;
use Validation::Class::Relatives;

use Validation::Class::Prototype;

{
    
    my  %CLASSES = ();
    
    sub return_class_proto {
        
        my $TARGET_CLASS = shift || caller(2);
        
        return $CLASSES{$TARGET_CLASS} ||= do {
            
            no strict 'refs';
            
            my $proto_class = 'Validation::Class::Prototype';
            
            my $proto = {
                package => $TARGET_CLASS,
                config  => {}
            };
            
            # respect foreign constructors (as is $class->new) if found
            
            my $new = $TARGET_CLASS->can("new") ?
                "initialize_validator" : "new"
            ;
            
            # injected into every derived class
            
            *{"$TARGET_CLASS\::$new"}      = sub { goto \&$new };
            *{"$TARGET_CLASS\::proto"}     = sub { goto \&prototype };
            *{"$TARGET_CLASS\::prototype"} = sub { goto \&prototype };
            
            # inject prototype class aliases unless exist
            
            my @aliases = $proto_class->proxy_methods;
            
            foreach my $alias (@aliases) {
                
                # slight-of-hand
                
                *{"$TARGET_CLASS\::$alias"} = sub {
                    
                    my $self = shift @_;
                    
                    my $proto = return_class_proto(ref $self); # isn't recursive
                    
                    $proto->$alias(@_);
                    
                }   unless $TARGET_CLASS->can($alias);
                
            }
            
            # inject wrapped prototype class aliases unless exist
            
            my @wrapped_aliases = $proto_class->proxy_methods_wrapped;
            
            foreach my $alias (@wrapped_aliases) {
                
                # slight-of-hand
                
                *{"$TARGET_CLASS\::$alias"} = sub {
                    
                    my $self = shift @_;
                    
                    my $proto = return_class_proto(ref $self); # isn't recursive
                    
                    $proto->$alias($self, @_);
                    
                }   unless $TARGET_CLASS->can($alias);
                
            }
            
            my $self = bless $proto, $proto_class;
            
            $self->{config} = merge $proto_class->configuration, $self->{config};
            
            $self; # return-once
            
        };
        
    }
    
    sub configure_class_proto {
        
        my $configuration_routine = pop;
        
        return undef unless "CODE" eq ref $configuration_routine;
        
        no strict 'refs';
        
        my $proto = return_class_proto shift;
        
        $configuration_routine->($proto);
        
        return $proto;
        
    }
    
}

sub import {
    
    my $caller = caller(0) || caller(1);
    
    if ($caller) {
        
        return_class_proto $caller # create prototype instance when used
        
    }
    
    strict->import;
    warnings->import;
    
    __PACKAGE__->export_to_level(1, @_);
    
}

sub initialize_validator {
    
    my $self   = shift;
    
    my $proto  = return_class_proto ref $self || $self;
    
    my $config = $proto->{config};
    
    # clone config values
    
    my @clonables = qw(fields filters methods mixins profiles relatives) ;
    
    $proto->{$_} = merge $proto->{config}->{uc $_}, $proto->{$_} for @clonables;
    
    my %ARGS = @_ ? @_ > 1 ? @_ : "HASH" eq ref $_[0] ? %{$_[0]} : () : ();
    
    # bless special collections
    
    $proto->{errors}
        = Validation::Class::Errors->new;
    
    $proto->{params}
        = Validation::Class::Params->new;
    
    $proto->{fields}
        = Validation::Class::Fields->new($proto->{fields}); #!!!
    
    $proto->{relatives}
        = Validation::Class::Relatives->new($proto->{relatives});
    
    # process overridden attributes
    
    my $fields = delete $ARGS{fields} if defined $ARGS{fields};
    my $params = delete $ARGS{params} if defined $ARGS{params};
    
    $proto->set_fields($fields) if $fields;
    $proto->set_params($params) if $params;
    
    # process attribute assignments
    
    while (my($attr, $value) = each (%ARGS)) {
        
        $self->$attr($value) if
            $config->{FIELDS}->{$attr}     ||
            $config->{ATTRIBUTES}->{$attr} ||
            grep { $attr eq $_ }
            ($proto->proxy_attributes)
        ;
        
    }
    
    # process plugins
    
    foreach my $plugin (keys %{$config->{PLUGINS}}) {
        
        $proto->plugins->{$plugin} =
            $plugin->new($self) if $plugin->can('new');
        
    }
    
    # process builders
    
    foreach my $builder (@{$config->{BUILDERS}}) {
        
        $builder->($self, %ARGS);
        
    }
    
    # initialize prototype
    
    $proto->normalize;
    $proto->apply_filters('pre') if $proto->filtering;
    
    # ready-set-go !!!
    
    return $self;
    
}

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
    
        # do something with the errors,
        # e.g. print $user->errors_to_string
    
    }
    
    1;

Validation::Class is a data validation framework and simple object system. It
allows you to model data and construct objects with focus on structure, 
reusability and data validation. It expects user input errors (without dying),
validation only occurs when you ask it to. Validation::Class classes are designed
to ensure consistency and promote reuse of data validation rules.

L<Validation::Class::Intro> will help you better understand the framework's
rationale and typical use-cases while L<Validation::Class::Prototype> will help
you discover all the bells-and-whistles included in the framework.

=head1 DESCRIPTION

Validation::Class is much more than a robust data validation framework, in-fact
it is more of a data modeling framework and can be used as an alternative to
minimalistic object systems such as L<Moo>, L<Mo>, etc. Validation::Class aims
to provide the building blocks for easily definable self-validating data models.
For more information on the validation class object system, review
L<"the object system"|/"THE OBJECT SYSTEM"> section.

Validation classes are typically defined using the following keywords:

    * field     - a field is a data validation rule
    * mixin     - a field template
    * directive - a field/mixin rule attribute
    * filter    - a directive which transforms the field parameter value
    * method    - a self-validating sub-routine
    * object    - a simple object builder

To keep your class namespace clean and free from pollution, all inherited
functionality is configured on your class' prototype (a cached class
configuration object) which leaves you free to create and overwrite method names
in your class without breaking the Validation::Class framework, this all happens
much in the same way L<Moose> uses it's MOP (meta-object-protocol) having most
of the framework functionality residing in the Moose::Meta namespace. For more
information on the validation class prototype, review
L<"the prototype class"|/"THE PROTOTYPE CLASS"> section.

One very important (and intentional) difference between Moose/Moose-like systems
and Validation::Class classes is in the handling of errors. There are generally
two types of errors that occur in an application, user-errors which are expected
and should be handled and reported, and system-errors which are unexpected and
should cause the application to terminate or otherwise handle the exception. It
is not always desired and/or appropriate to crash from a failure to validate a
particular parameter. In Validation::Class, the application is not terminated or
validate automatically unless you configure it to.

Additionally, please review the L<Validation::Class::Intro> for a more in-depth
understanding of how to leverage Validation::Class.

=cut

=keyword attribute

The attribute keyword (or has) creates a class attribute. This is only a
minimalistic variant of what you may have encountered in other object systems
such as L<Moose>, L<Mouse>, L<Moo>, L<Mo>, etc.

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
    
    my ($attrs, $default) = @_;

    return unless $attrs;

    confess "Error creating accessor, default must be a coderef or constant"
        if ref $default && ref $default ne 'CODE';

    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';

    for my $attr (@$attrs) {

        confess "Error creating accessor '$attr', name has invalid characters"
            unless $attr =~ /^[a-zA-Z_]\w*$/;
        
        my $code ;
        
        if (defined $default) {
            
            $code = sub {
                
                if (@_ == 1) {
                    return $_[0]->{$attr} if exists $_[0]->{$attr};
                    return $_[0]->{$attr} = ref $default eq 'CODE' ?
                        $default->($_[0]) : $default;
                }
                $_[0]->{$attr} = $_[1]; $_[0];
                
            };
            
        }
        
        else {
            
            $code = sub {
                
                return $_[0]->{$attr} if @_ == 1;
                $_[0]->{$attr} = $_[1]; $_[0];
                
            };
            
        }
        
        return configure_class_proto $package => sub {
            
            my ($proto) = @_;
            
            my $accessors = $proto->{config}->{ATTRIBUTES} ||= {};
            
            no strict 'refs';
            no warnings 'redefine';
            
            *{"$proto->{package}\::$attr"} = $accessors->{$attr} = $code;
            
        };

    }
    
}

=keyword build

The build keyword (or bld) registers a coderef to be run at instantiation much
in the same way the common BUILD routine is used in modern-day OO systems.

    package MyApp::User;
    
    use Validation::Class;
    
    build sub {
        
        my ($self, %args) = @_;
        
        # ... do something
        
    };
    
    # die like a Moose
    
    use Carp;
    
    build sub {
        
        my ($self, %args) = @_;
        
        my @attributes = qw();
        
        foreach my $attribute (@attributes) {
            
            confess "Attribute ($attribute) is required"
                unless $self->$attribute;
            
        }
        
    };

The build keyword takes one argument, a coderef which is passed the instantiated
class object.

=cut

sub bld { goto &build }
sub build {
    
    my $package = shift if @_ == 2;
    
    my ($code) = @_;
    
    return undef unless ("CODE" eq ref $code);
    
    return configure_class_proto $package => sub {
        
        my ($proto) = @_;
        
        $proto->{config}->{BUILDERS} ||= [];
        
        push @{$proto->{config}->{BUILDERS}}, $code;
        
    };
    
}

=keyword directive

The directive keyword (or dir) creates custom validator directives to be used in
your field definitions. It is a means of extending the pre-existing directives
table before runtime and is ideal for creating custom directive extension
packages to be used in all your classes.

    package MyApp::Directives;
    
    use Validation::Class;
    use Data::Validate::Email;
    
    directive 'is_email' => sub {
    
        my ($dir, $value, $field, $self) = @_;
        
        my $validator = Data::Validate::Email->new;
        
        unless ($validator->is_email($value)) {
        
            my $handle = $field->{label} || $field->{name};
            
            $field->{errors}->add("$handle must be a valid email address");
            
            return 0;
        
        }
        
        return 1;
    
    };
    
    package MyApp::User;
    
    use Validate::Class;
    use MyApp::Directives;
    
    field 'email' => {
        is_email => 1,
        ...
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
    
    my ($name, $data) = @_;
    
    return undef unless ($name && $data);
    
    return configure_class_proto $package => sub {
        
        my ($proto) = @_;
        
        $proto->{config}->{DIRECTIVES} ||= {};
        
        $proto->{config}->{DIRECTIVES}->{$name} = {
            
            mixin     => 1,
            field     => 1,
            validator => $data
            
        };
        
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
    
    field 'preference.send_reminders.text:0' => {
        ...
    };
    
    my $value = $self->login;
    
    $self->login($new_value); # arrayrefs and hashrefs will be flattened
    
    $self->preference_send_reminders;
    
    $self->preference_send_reminders_text_0;

Protip: Field directives are used to validate scalar and array data. Don't use
fields to store and validate blessed objects. Please see the *has* keyword
instead.

=cut

sub fld { goto &field }
sub field {
    
    my $package = shift if @_ == 3;
    
    my ($name, $data) = @_;
    
    return undef unless ($name && $data);
    
    confess "Error creating field $name, name is using unconventional naming"
        unless $name =~ /^[a-zA-Z_](([\w\.]+)?\w)$/
        xor    $name =~ /^[a-zA-Z_](([\w\.]+)?\w)\:\d+$/;
    
    return configure_class_proto $package => sub {
        
        my ($proto) = @_;
    
        $proto->{config}->{FIELDS} ||= {};
        
        confess "Error creating accessor $name on $proto->{package}, ".
            "attribute collision" if exists $proto->{config}->{FIELDS}->{$name};
        
        confess "Error creating accessor $name on $proto->{package}, ".
            "method collision" if $proto->{package}->can($name);
        
        $data->{name} = $name;
        
        $proto->{config}->{FIELDS}->{$name} = $data;
        
        no strict 'refs';
        
        my $accessor = $name;
        
        $accessor =~ s/[^a-zA-Z0-9_]/_/g;
        
        my $accessor_routine = sub {
            
            my ($self, $data) = @_;
            
            my $proto  = $self->proto;
            my $fields = $proto->fields;
            my $result = undef;
            
            if (defined $data) {
                
                $proto->set_params($name => $data);
                
            }
            
            $result = $proto->get_value($name);
            
            return $result;
            
        };
        
        *{"$proto->{package}\::$accessor"} = $accessor_routine;
        
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
    
    my ($name, $data) = @_;
    
    return undef unless ($name && $data);
    
    return configure_class_proto $package => sub {
        
        my ($proto) = @_;
        
        $proto->{config}->{FILTERS} ||= {};
        
        $proto->{config}->{FILTERS}->{$name} = $data;
        
    };
    
}

=keyword load

The load keyword (or set), which can also be used as a method, provides options
for extending the current class by attaching other L<Validation::Class> classes
as relatives, roles, plugins, etc. The process of applying roles to the current
class mainly involve copying the role's methods and configuration.

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
        
        my $name = $proto->{package};
        
        $proto->{config}->{BUILDERS} ||= [];
        
        if ($data->{classes}) {
            
            my @parents ;
            
            if (! ref $data->{classes} && $data->{classes} == 1) {
                
                push @parents, $name;
                
            }
            
            else {
            
                push @parents, "ARRAY" eq ref $data->{classes} ?
                    @{$data->{classes}} : $data->{classes};
            
            }
            
            foreach my $parent (@parents) {
                
                # load class children and create relationship map (hash)
                
                foreach my $child (findallmod $parent) {
                
                    my $nickname  = $child;
                       $nickname  =~ s/^$parent\:://;
                    
                    $proto->{config}->{RELATIVES} ||= {};
                    $proto->{config}->{RELATIVES}->{$nickname} = $child;
                
                }
                
            }
            
        }
        
        if ($data->{plugins}) {
            
            my @plugins ;
            
            push @plugins, "ARRAY" eq ref $data->{plugins} ?
                @{$data->{plugins}} : $data->{plugins};
            
            foreach my $plugin (@plugins) {
        
                if ($plugin !~ /^\+/) {
            
                    $plugin = "Validation::Class::Plugin::$plugin";
            
                }
                
                $plugin =~ s/^\+//;
                
                eval { use_module $plugin };
                
            }
            
            $proto->{config}->{PLUGINS}->{$_} = undef for @plugins;
            
        }
        
        # attach roles
        
        if (grep { $data->{$_} } qw/base bases role roles/) {
            
            my @roles ;
            
            my $alias =
                $data->{base}  || $data->{role} ||
                $data->{roles} || $data->{bases}; # backwards compat
            
            if ($alias) {
                
                push @roles, "ARRAY" eq ref $alias ?
                    @{$alias} : $alias;
                
            }
            
            if (@roles) {
                
                foreach my $role (@roles) {
                    
                    eval { use_module $role };
                    
                    no strict 'refs';
                    
                    my @routines = grep { defined &{"$role\::$_"} }
                        keys %{"$role\::"};
                    
                    if (@routines) {
                        
                        # copy methods
                        
                        foreach my $routine (@routines) {
                            
                            eval {
                            
                                *{"$proto->{package}\::$routine"} =
                                *{"$role\::$routine"}
                            
                            } unless $proto->{package}->can($routine);
                            
                        }
                        
                        my $role_proto = return_class_proto $role;
                        
                        $proto->{config}       ||= {}; # good measure
                        $role_proto->{config}  ||= {}; # good measure
                        
                        # merge configs
                        
                        $proto->{config} =
                            merge $proto->{config}, $role_proto->{config};
                        
                    }
                    
                }
                
            }
            
        }
        
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

    return undef unless ($name && $data);
    
    return configure_class_proto $package => sub {
        
        my ($proto) = @_;
        
        $proto->{config}->{METHODS}    ||= {};
        $proto->{config}->{ATTRIBUTES} ||= {};
        
        confess "Error creating method $name on $proto->{package}, ".
            "collides with attribute $name"
                if exists $proto->{config}->{ATTRIBUTES}->{$name};
        
        confess "Error creating method $name on $proto->{package}, ".
            "collides with method $name"
                if $proto->{package}->can($name);
        
        # create method
        
        confess "Error creating method $name, requires 'input' and 'using' options"
            unless $data->{input} && $data->{using};
        
        $proto->{config}->{METHODS}->{$name} = $data;
        
        no strict 'refs';
        
        *{"$proto->{package}\::$name"} = sub {
            
            my $self  = shift;
            my @args  = @_;
            
            my $validator;
            
            my $input  = $data->{'input'};
            my $using  = $data->{'using'};
            my $output = $data->{'output'};
            
            if ($input) {
            
                $validator = "ARRAY" eq ref $input ?
                    
                    # validate fields
                    sub { $self->validate(@{$input}) } :
                    
                    # validate profile
                    sub { $self->validate_profile($input, @args) } ;
            
            }
            
            if ($using) {
                
                if ("CODE" eq ref $using) {
                    
                    my $error = "Method $name failed to validate";
                        
                    # run input validation
                    if ("CODE" eq ref $validator) {
                        
                        unless ($validator->(@args)) {
                        
                            unshift @{$self->errors}, $error
                                if $self->report_failure;
                            
                            confess $error. " input, ". $self->errors_to_string
                                if ! $self->ignore_failure;
                            
                            return undef;
                            
                        }
                        
                    }
                    
                    # execute routine
                    my $return = $data->{using}->($self, @args);
                    
                    # run output validation
                    if ($output) {
                        
                        $validator = "ARRAY" eq ref $output ?
                            
                            # validate fields
                            sub { $self->validate(@{$output}) } :
                            
                            # validate profile
                            sub { $self->validate_profile($output, @args) } ;
                        
                        confess $error. " output, ". $self->errors_to_string
                            unless $validator->(@args);
                        
                    }
                    
                    return $return;
                    
                }
                
                else {
                    
                    confess "Error executing $name, no associated coderef";
                    
                }
                
            }
            
            return undef;
            
        };
        
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
    
    return undef unless ($name && $data);

    return configure_class_proto $package => sub {
        
        my $proto = shift;
        
        $proto->{config}->{MIXINS} ||= {};
        
        $proto->{config}->{MIXINS}->{$name} = $data;
        
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

=keyword object

The object keyword (or obj) registers a class object builder which builds and
returns a class object on-demand. The object keyword also creates a method on
the calling class which invokes the builder. Unlike class attributes, this
method does not cache or otherwise store the returned class object it
constructs.

    package MyApp::Database;
    
    use DBI;
    use Validation::Class;
    
    fld name => {
        required => 1,
    };
    
    fld host => {
        required => 1,
    };
    
    fld port => {
        required => 1,
    };
    
    fld user => {
        required => 1,
    };
    
    fld pass => {
        # ...
    };
    
    obj _build_dbh => {
        type => 'DBI',
        init => 'connect', # defaults to new
        args => sub {
            
            my ($self) = @_;
            
            my @conn_str_parts =
                ('dbi', 'mysql', map { $self->$_ } qw(name host port));
            
            return (join(':', @conn_str_parts), $self->user, $self->pass);
            
        }
    };
    
    has dbh => sub { shift->_build_dbh }; # cache the _build_dbh object
    
    sub connect {
    
        my ($self) = @_;
        
        my @parameters = ('name', 'host', 'port', 'user');
        
        if ($self->validate(@parameters)) {
        
            if ($self->dbh) {
                
                my $db = $self->dbh;
                
                # ... do something else with DBI
                
                return 1;
                
            }
            
            $self->set_errors($DBI::errstr);
        
        }
        
        return 0;
    
    }
    
    package main;
    
    my $database = MyApp::Database->new(
        name => 'test',
        host => 'localhost',
        port => '3306',
        user => 'root'
    );
    
    if ($database->connect) {
    
        # ...
    
    }
    
The object keyword takes two arguments, an object builder name and a hashref
of key/value pairs which are used to instruct the builder on how to construct
the object. The supplied hashref should be configured as follows:

    {
    
        # class to construct
        type => 'ClassName',
        
        # optional: constructor name (defaults to new)
        init => 'new',
        
        # optional: coderef which returns arguments for the constructor
        args => sub {}
        
    }

=cut

sub obj { goto &object }
sub object {

    my $package = shift if @_ == 3;
    
    my ($name, $data) = @_;

    return undef unless ($name && $data);
    
    return configure_class_proto $package => sub {
        
        my ($proto) = @_;
        
        $proto->{config}->{OBJECTS}    ||= {};
        $proto->{config}->{ATTRIBUTES} ||= {};
        
        confess "Error creating method $name on $proto->{package}, ".
            "collides with attribute $name"
                if exists $proto->{config}->{ATTRIBUTES}->{$name};
        
        confess "Error creating method $name on $proto->{package}, ".
            "collides with method $name"
                if $proto->{package}->can($name);
        
        # create method
        
        confess "Error creating method $name, requires a 'type' option"
            unless $data->{type};
        
        $proto->{config}->{OBJECTS}->{$name} = $data;
        
        no strict 'refs';
        
        *{"$proto->{package}\::$name"} = sub {
            
            my $self  = shift;
            my @args  = @_;
            
            my $validator;
            
            my $type = $data->{'type'};
            my $init = $data->{'init'} ||= 'new';
            my $args = $data->{'args'};
            
            my @params = ($args->($self)) if "CODE" eq ref $args;
            
            # maybe merge @params with @args or vice versa ???
            
            if (my $instance = $type->$init(@params)) {
                
                return $instance;
                
            }
            
            return undef;
            
        };
        
    };

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
    
    my ($name, $data) = @_;

    return undef unless ($name && "CODE" eq ref $data);
    
    return configure_class_proto $package => sub {
        
        my ($proto) = @_;
        
        $proto->{config}->{PROFILES} ||= {};
        
        $proto->{config}->{PROFILES}->{$name} = $data;
        
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

=head1 THE PROTOTYPE CLASS

This module provides mechanisms (sugar functions to model your data) which allow
you to define self-validating classes. Each class you create is associated with
a *prototype* class which provides data validation functionality and keeps your
class' namespace free from pollution, please see L<Validation::Class::Prototype>
for more information on specific methods, and attributes.

All derived classes will have a prototype-class attached to it which does all
the heavy lifting (regarding validation and error handling). The prototype
injects a few proxy methods into your class which are basically aliases to your
prototype class methods, however it is possible to access the prototype directly 
using the proto/prototype methods.


    package MyApp::User;
    
    use Validation::Class;
    
    package main;
    
    my $user  = MyApp::User->new;
    my $proto = $user->prototype;
    
    $proto->error_count # same as calling $self->error_count


=head1 THE OBJECT SYSTEM

All derived classes will benefit from the light-weight, straight-forward and
simple object system Validation::Class provides. The conventional constructor
C<new> should be used to instantiate a new object, and the C<bld>/C<build>
keywords can be used to hook into the instantiation process. Your classes can
be configured to cooperate with an existing design or modern OO framework like
L<Moose>, L<Mouse>, L<Moo>, etc. The following example explains how to setup a
Validation::Class class in cooperation with Moose (while this example focuses
on Moose, the approach is the same regardless of the existing system):

    # MOOSE AS YOUR PRIMARY OO SYSTEM
    
    package MyApp;
    
    use Moose;
    use Validation::Class '!has'; # in cooperative mode, dont export has()
    
    # you must run initialization routines yourself ...
    # specifying it in a BUILD routine will run it automatically
    
    sub BUILD {
        
        my ($self, $args) = @_;
        
        $self->initialize_validator(
            params => $args->{params}
        );
        
    }
    
    field login     => {
        min_length  => 5
        max_length  => 50
    };
    
    field password  => {
        min_length  => 8,
        min_symbols => 1
        max_length  => 50
    };
    
    # MOOSE AS YOUR SECONDARY/BACKUP OO SYSTEM
    
    package MyApp;
    
    use Validation::Class '!has'; # avoids has() keyword clash
    use Moose;
    
    has foo => (
        is => 
    );
    
    field login     => {
        min_length  => 5
        max_length  => 50
    };
    
    field password  => {
        min_length  => 8,
        min_symbols => 1
        max_length  => 50
    };
    
    1;

This cooperation works by simply detecting the existence of a method named C<new>, 
the name traditionally reserved for a class constructor which if detected signals
Validation::Class to install a method named C<initialize> as opposed to installing
its own constructor. The installed method, C<initialize>, encapsulates the
functionality which prepares the class for interaction with its corresponding
prototype class, this function must be called before using the Validation::Class
features provided. If this concept isn't clear to you you needn't worry as this
is very low-level, all you need you understand is that Validation::Class
will install a constructor or a method named initialize if a constructor already
exists, either way, the installed method should be called before executing
methods on the class.

As previously stated, Validation::Class injects a few proxy methods into your 
class which are basically aliases to your prototype class methods. You can 
find additional information on the prototype class and its method at 
L<Validation::Class::Prototype>. The following is a list of *proxy* methods, 
methods which are injected into your class as shorthand to methods defined in 
the prototype class (these methods are overridden):

=head2 class

    $self->class;
 
See L<Validation::Class::Prototype/class> for full documentation.

=head2 clear_queue

    $self->clear_queue;
 
See L<Validation::Class::Prototype/clear_queue> for full documentation.

=head2 error_count

    $self->error_count;
 
See L<Validation::Class::Prototype/error_count> for full documentation.

=head2 error_fields

    $self->error_fields;
 
See L<Validation::Class::Prototype/error_fields> for full documentation.

=head2 errors

    $self->errors;
 
See L<Validation::Class::Prototype/errors> for full documentation.

head2 errors_to_string

    $self->errors_to_string;
 
See L<Validation::Class::Prototype/errors_to_string> for full 
documentation.

=head2 get_errors

    $self->get_errors;
 
See L<Validation::Class::Prototype/get_errors> for full documentation.

=head2 get_fields

    $self->get_fields;
 
See L<Validation::Class::Prototype/get_fields> for full documentation.

=head2 get_params

    $self->get_params;
 
See L<Validation::Class::Prototype/get_params> for full documentation.

=head2 fields

    $self->fields;
 
See L<Validation::Class::Prototype/fields> for full documentation.

=head2 filtering

    $self->filtering;
 
See L<Validation::Class::Prototype/filtering> for full documentation.

=head2 hash_inflator

    $self->hash_inflator;
 
See L<Validation::Class::Prototype/hash_inflator> for full 
documentation.

=head2 ignore_failure

    $self->ignore_failure;
 
See L<Validation::Class::Prototype/ignore_failure> for full 
documentation.

=head2 ignore_unknown

    $self->ignore_unknown;
 
See L<Validation::Class::Prototype/ignore_unknown> for full 
documentation.

=head2 param

    $self->param;
 
See L<Validation::Class::Prototype/param> for full documentation.

=head2 params

    $self->params;
 
See L<Validation::Class::Prototype/params> for full documentation.

=head2 plugin

    $self->plugin;
 
See L<Validation::Class::Prototype/plugin> for full documentation.

=head2 queue

    $self->queue;
 
See L<Validation::Class::Prototype/queue> for full documentation.

=head2 report_failure

    $self->report_failure;
 
See L<Validation::Class::Prototype/report_failure> for full 
documentation.

=head2 report_unknown

    $self->report_unknown;
 
See L<Validation::Class::Prototype/report_unknown> for full documentation.

=head2 reset_errors

    $self->reset_errors;
 
See L<Validation::Class::Prototype/reset_errors> for full documentation.

=head2 reset_fields

    $self->reset_fields;
 
See L<Validation::Class::Prototype/reset_fields> for full documentation.

=head2 reset_params

    $self->reset_params;
 
See L<Validation::Class::Prototype/reset_params> for full documentation.

=head2 set_errors

    $self->set_errors;
 
See L<Validation::Class::Prototype/set_errors> for full documentation.

=head2 set_fields

    $self->set_fields;
 
See L<Validation::Class::Prototype/set_fields> for full documentation.

=head2 set_params

    $self->set_params;
 
See L<Validation::Class::Prototype/set_params> for full documentation.

=head2 set_method

    $self->set_method;
 
See L<Validation::Class::Prototype/set_method> for full documentation.

=head2 stash

    $self->stash;
 
See L<Validation::Class::Prototype/stash> for full documentation.

=head2 validate

    $self->validate;
 
See L<Validation::Class::Prototype/validate> for full documentation.

=head2 validate_profile

    $self->validate_profile;
 
See L<Validation::Class::Prototype/validate_profile> for full documentation.

=head1 EXTENDING VALIDATION::CLASS

Validation::Class does NOT provide
method modifiers but can be easily extended with L<Class::Method::Modifiers>.

=cut

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

=cut

=head1 SEE ALSO

You might do well to look into L<Validate::Tiny> for simple use-cases, it has
virtually no dependencies and solid test coverage. L<Data::Verifier> is a great
approach to adding robust validation options to your existing Moose classes. I
have also heard some good things about L<Data::FormValidator> as well.

=cut

1;