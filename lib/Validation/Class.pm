# ABSTRACT: Low-Fat Full-Flavored Data Modeling and Validation Framework

use strict;
use warnings;

package Validation::Class;

use 5.008001;
use strict;
use warnings;

# VERSION

use Module::Find;
use Carp 'confess';
use Hash::Merge 'merge';
use Exporter ();

use Validation::Class::Engine; # used-as-role, see new()

our @ISA    = qw(Exporter);
our @EXPORT = qw(
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
    load_classes
    load_plugins
    
    mth
    method
    mxn
    mixin
    
    new
    
    pro
    profile
);

=head1 SYNOPSIS

    use MyApp;
    
    my $params = {
       'user.login' => '...',
       'user.pass' => '...'
    };
    
    my $app = MyApp->new(params => $params);
    
    my $user = $app->class('user');
    
    unless ($user->validate('login', 'pass')){
    
        # do something with ... $input->errors;
        # or print $input->errors_to_string;
        
    }

=head1 DESCRIPTION

Validation::Class is much more than a simple data validation framework, in-fact
it is more of a data modeling framework and can be used as an alternative to
minimalistic object systems such as L<Moo>, L<Mo>, etc.

Validation::Class aims to provide the building blocks for easily defining
self-validating data models.

When fields (attributes with validation rules) are defined, accessors are
automatically generated to make getting and setting their values much easier.

Methods can be defined using the method keyword which can make the routine
self-validating, checking the defined input requirements against existing
validation rules before executing the routine gaining consistency and security.

    package MyVal::User;
    
    use Validation::Class;
    
    mxn basic    => { ... }; # rules mixin
    
    fld name     => { ... }; # attr w/rules
    fld email    => { ... }; # attr w/rules
    fld login    => { ... }; # attr w/rules
    fld password => { ... }; # attr w/rules
    
    has attitude => 1; # just an attr
    
    mth create   => { ... }; # self-validating method
    
    package main;
    
    my $user = MyVal::User->new(name => '...', email => '...');
    
    if ($user->create) {
    
        print "Account created for " . $user->name;
    
    }
    
    else {
    
        # did you forget your login and pass?
    
    }
    
    1;


Validation::Class takes a different approach towards data validation, it
centralizes data validation rules to ensure consistency through DRY
(dont-repeat-yourself) code.

=cut

=keyword attribute

The attribute keyword (or has) creates a class attribute. 

    package MyApp::User;
    
    use Validate::Class;
    
    has 'attitude' => sub {
        
        return $self->bothered ? 1 : 0 
        
    };
    
    1;
    
The attribute keyword takes two arguments, the attribute name and a constant or
coderef that will be used as its default value.

=cut

sub has { goto &attribute }
sub attribute {
    
    my ($attrs, $default) = @_;

    my $self = caller(0);

    return unless $attrs;

    confess "Error creating accessor, default must be a coderef or constant"
      if ref $default && ref $default ne 'CODE';

    $attrs = [$attrs] unless ref $attrs eq 'ARRAY';

    for my $attr (@$attrs) {

        confess "Error creating accessor \"$attr\", name has invalid characters"
            unless $attr =~ /^[a-zA-Z_]\w*$/;

        my $stmnt;

        $stmnt = <<"STMNT";
        sub {
            
            if (\@_ == 1) { 
STMNT

        $stmnt .= <<"STMNT" unless (defined $default);
                return \$_[0]->{'$attr'};
STMNT
        
        $stmnt .= <<"STMNT" if ref $default eq 'CODE';
                return \$_[0]->{'$attr'} if exists \$_[0]->{'$attr'};
                return \$_[0]->{'$attr'} = \$default->(\$_[0]);
STMNT

        $stmnt .= <<"STMNT" if ref $default ne 'CODE';
                return \$_[0]->{'$attr'} if exists \$_[0]->{'$attr'};
                return \$_[0]->{'$attr'} = \$default;
STMNT
        
        $stmnt .= <<"STMNT";
            }
            
            \$_[0]->{'$attr'} = \$_[1];
            \$_[0];
        }
STMNT
        
        no strict 'refs';
        no warnings 'redefine';
        
        *{$self."::$attr"} = eval $stmnt;

        confess($self . " attribute compiler error: \n$stmnt\n$@\n") if $@;

    }
    
}

=keyword build

The build keyword (or bld) registers a coderef to be run at instantiation much
in the same way the common BUILD routine is used in modern-day OO systems.

    package MyApp::User;
    
    use Validation::Class;
    
    build sub {
        
        my $self = shift;
        
        # ... do something
        
    };

The build keyword takes one argument, a coderef which is passed the instantiated
class object.

=cut

sub bld { goto &build }
sub build {
    
    my ($code) = @_;
    
    my $self = caller(0);
    
    return 0 unless ("CODE" eq ref $code);
    
    no strict 'refs';
        
    push @{$self->{config}->{BUILDERS}}, $code;
    
    return $code;
    
}

=keyword directive

The directive keyword (or dir) creates custom validator directives to be used in
your field definitions. It is a means of extending the pre-existing directives
table before runtime and is ideal for creating custom directive extension
packages to be used in all your classes.

    package MyApp::Directives;
    
    use Validation::Class;
    ues Data::Validate::Email;
    
    directive 'is_email' => sub {
    
        my ($dir, $value, $field, $self) = @_;
        
        my $validator = Data::Validate::Email->new;
        
        unless ($validator->is_email($value)) {
        
            my $handle = $field->{label} || $field->{name};
            $class->error($field, "$handle must be a valid email address");
            
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

=cut

sub dir { goto &directive }
sub directive {
    
    my ($name, $data) = @_;
    
    my $self = caller(0);
    
    return 0 unless ($name && $data);
    
    no strict 'refs';
        
    $self->{config}->{DIRECTIVES}->{$name} = {
        mixin     => 1,
        field     => 1,
        validator => $data
    };
    
    return $name, $data;
    
}

=keyword field

The field keyword (or fld) creates an attribute with validation rules for reuse
in code. The field keyword may also correspond with the parameter name expected to
be passed to your validation class.

    package MyApp::User;
    
    use Validation::Class;
    
    field 'login' => {
        required   => 1,
        min_length => 1,
        max_length => 255,
        ...
    };
    
The field keyword takes two arguments, the field name and a hashref of key/values
pairs known as directives.

Protip: Fields are used to validate constant and array data, not hashrefs and
objects. Don't try to use fields like attributes (use the has keyword instead).

=cut

sub fld { goto &field }
sub field {
    
    my ($name, $data) = @_;
    
    my $self = caller(0);
    
    return 0 unless ($name && $data);
    
    no strict 'refs';
    
    $self->{config}->{FIELDS}->{$name} = $data;
    $self->{config}->{FIELDS}->{$name}->{errors} = [];
    
    return $name, $data;
    
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
    
    my ($name, $data) = @_;
    
    my $self = caller(0);
    
    return 0 unless ($name && $data);
    
    no strict 'refs';
    
    $self->{config}->{FILTERS}->{$name} = $data;
    
    return $name, $data;
    
}

=keyword load

The load keyword, which can also be used as a method, provides options for
further configuring the calling class. 

    package MyApp;
    
    use Validation::Class;
    
    # load specific child class
    
    load {
        ...
    };
    
    1;

The C<load.class> option, can be a constant or arrayref, will require other
classes specifically and add them to the relationship map for convenient access
through the class() method. Existing parameters and configuration options are
passed to the child class' constructor. All attributes can be easily overwritten
using the attribute's accessors on the child class.

    package MyApp;
    
    use Validation::Class;
    
    # load specific child class
    
    load {
        class => 'MyApp::Relative'
    };
    
    package main;
    
    my $app = MyApp->new;
    
    my $rel = $app->class('relative'); # instantiated MyApp::Relative object
    my $rel = $app->class('MyApp::Relative'); # alternatively
    
    1;

The C<load.classes> option, can be a constant or arrayref, uses L<Module::Find>
to load B<all> child classes (in-all-subdirectories) for convenient access
through the class() method. Existing parameters and configuration options are
passed to the child class' constructor. All attributes can be easily overwritten
using the attribute's accessors on the child class.


    package MyApp;
    
    use Validation::Class;
    
    # load specific child class
    
    load {
        classes => 1
    };
    
    package main;
    
    my $app = MyApp->new;
    
    my $rel = $app->class('relative'); # instantiated MyApp::Relative object
    my $rel = $app->class('MyApp::Relative'); # alternatively
    
    my $rel = $app->class('data_source'); # MyApp::DataSource
    my $rel = $app->class('data_source-first'); # MyApp::DataSource::First
    
    1;
    

The C<load.plugins> option is used to load plugins that support Validation::Class. 
A Validation::Class plugin is little more than a class that implements a "new"
method that extends the associated validation class object. As usual, an official
Validation::Class plugin can be referred to using shorthand while custom plugins
are called by prefixing a plus symbol to the fully-qualified plugin name. Learn
more about plugins at L<Validation::Class::Cookbook>.

    package MyVal;
    
    load {
        plugins => [
            'CPANPlugin', # Validation::Class::Plugin::CPANPlugin
            '+MyVal::Plugin'
        ]
    };
    
    1;

=cut

sub load {
    
    my $data = pop @_;
    my $self = pop @_;
    
    $self ||= caller(0); # hackaroni toni
    
    no strict 'refs';

    if ($data->{class}) {
        
        my $classes = [];
        
        push @$classes, "ARRAY" eq ref $data->{class} ?
            @{$data->{class}} : $data->{class};
        
        foreach my $class (@$classes) {
            
            my $child = $class;
            
            # require plugin
            my $file = $class;
               $file =~ s/::/\//g;
               $file .= ".pm";
            
            eval "require $class"
                unless $INC{$file}; # unless already loaded
            
            # load class child and create relationship map (hash)
        
            my $nickname  = $child;
               $nickname  =~ s/^$self//;
               $nickname  =~ s/^:://;
               $nickname  =~ s/([a-z])([A-Z])/$1\_$2/g;
               $nickname  =~ s/::/-/g;
               
            my $quickname = $child;
               $quickname =~ s/^$self//;
               $quickname =~ s/^:://;
               
            $self->{relatives}->{lc $nickname} = $child;
            $self->{relatives}->{$quickname}   = $child;
            
        }
        
    }
    
    if ($data->{classes}) {
        
        my $parents = [];
        
        if ($data->{classes} == 1) {
            
            push @$parents, $self;
            
        }
        
        push @$parents, "ARRAY" eq ref $data->{classes} ?
            @{$data->{classes}} : $data->{classes};
        
        foreach my $parent (@$parents) {
            
            # load class children and create relationship map (hash)
            foreach my $child (useall $parent) {
            
                my $nickname  = $child;
                   $nickname  =~ s/^$self//;
                   $nickname  =~ s/^:://;
                   $nickname  =~ s/([a-z])([A-Z])/$1\_$2/g;
                   $nickname  =~ s/::/-/g;
                   
                my $quickname = $child;
                   $quickname =~ s/^$self//;
                   $quickname =~ s/^:://;
                   
                $self->{relatives}->{lc $nickname} = $child;
                $self->{relatives}->{$quickname}   = $child;
            
            }
            
        }
        
    }
    
    if ($data->{plugins}) {
        
        my @plugins = @{ $data->{plugins} };
        
        foreach my $plugin (@plugins) {
    
            if ($plugin !~ /^\+/) {
        
                $plugin = "Validation::Class::Plugin::$plugin";
        
            }
            
            $plugin =~ s/^\+//;
            
            # require plugin
            my $file = $plugin;
               $file =~ s/::/\//g;
               $file .= ".pm";
            
            eval "require $plugin"
                unless $INC{$file}; # unless already loaded
        
        }
        
        $self->{config}->{PLUGINS}->{$_} = 1 for @plugins;
        
    }
    
    # attached base classes (configs)
    if ($data->{base}) {
        
        $data->{base} = [$data->{base}] unless "ARRAY" eq ref $data->{base};
        
        if (@{$data->{base}}) {
            
            foreach my $class (@{$data->{base}}) {
                
                # require plugin
                my $file = $class;
                   $file =~ s/::/\//g;
                   $file .= ".pm";
                
                eval "require $class"
                    unless $INC{$file}; # unless already loaded
                    
                # merge configs
                $self->{config} = merge $class->{config}, $self->{config};
                
            }
            
        }
        
    }
    
    return $self;
    
}

# TO BE DEPRECIATED
sub load_classes {
    
    my $self = shift @_;
    
    return $self->load({ classes => 1 });
    
}

# TO BE DEPRECIATED
sub load_plugins {
    
    my $self = shift @_;
    
    return $self->load({ plugins => [@_] });
    
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
        output => ['+id'], # optional output validation
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

    my ($name, $data) = @_;
    my $self = caller(0);
    
    return 0 unless ($name && $data);
    
    no strict 'refs';
    
    $self->{config}->{METHODS}->{$name} = $data;
    
    return $name, $data;

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

    my ($name, $data) = @_;
    my $self = caller(0);
    
    return 0 unless ($name && $data);
    
    no strict 'refs';
    
    $self->{config}->{MIXINS}->{$name} = $data;
    
    return $name, $data;

}

=method new

The new method, exported into the calling namespace automatically, should NOT be
tampered with. The new method performs a series of actions (magic) required for
the class to function properly. See the build keyword for hooking into the
instantiation process.

    package MyApp;
    
    use Validation::Class;
    
    package main;
    
    my $app = MyApp->new;
    
    ...

=cut

sub new {

    my $invocant = shift;
    
    my $engine = 'Validation/Class/Engine.pm'; # class role, manually
    
    $engine =~ s/\//::/g;
    $engine =~ s/\.pm$//;
    
    no strict 'refs';
    
    my @routines = grep {
        
        defined &{"$engine\::$_"} && $_ ne 'has'
    
    } keys %{"$engine\::"};
    
    # apply engine as a role
    
    foreach my $routine (@routines) {
        
        eval { *{"$invocant\::$routine"} = \&{"$engine\::$routine"} };
        
    }
    
    # create config
    
    $invocant->{config} = merge $engine->template, $invocant->{config};
    
    # start instantiation
    
    my $self = bless { %{ $invocant } }, ref $invocant || $invocant;
    
    # create class attributes (parameter accessors)
    
    while (my ($key, $value) = each(%{ $self->fields })) {
        
        confess "Error creating accessor $key, attribute collision"
            if exists $self->{$key};
            
        confess "Error creating accessor $key, base-class method collision"
            if $self->can($key) and defined &{"$engine\::$key"};
            
        confess "Error creating accessor $key, reserve word collision"
            if $self->can($key) and grep { $key eq $_ } @EXPORT;
        
        # create accessor
        
        $self->set_method($key => sub {
            
            my ($self, $data) = @_;
            
            $self->params->{$key} = $data if defined $data;
            
            return exists $self->params->{$key} ? $self->params->{$key} : undef;
            
        }) unless $self->can($key); # I already can
        
    }
    
    # create class methods (from signatures)
    
    while (my ($key, $value) = each(%{ $self->methods })) {
        
        confess "Error creating method $key, attribute collision"
            if exists $self->{$key};
            
        confess "Error creating method $key, base-class method collision"
            if $self->can($key) and defined &{"$engine\::$key"};
            
        confess "Error creating method $key, reserve word collision"
            if $self->can($key) and grep { $key eq $_ } @EXPORT;
        
        # create method
        
        next unless $value->{input} && $value->{using};
        
        $self->set_method($key => sub {
            
            my $self  = shift;
            my @args  = @_;
            
            my $validator;
            
            my $input  = $value->{'input'};
            my $using  = $value->{'using'};
            my $output = $value->{'output'};
            
            if ($input) {
            
                $validator = "ARRAY" eq ref $input ?
                    
                    # validate fields
                    sub { $self->validate(@{$input}) } :
                    
                    # validate profile
                    sub { $self->validate_profile($input, @_) } ;
            
            }
            
            if ($using) {
                
                if ("CODE" eq ref $using) {
                    
                    my $error = "method $key failed to validate";
                        
                    # run input validation
                    if ("CODE" eq ref $validator) {
                        
                        unless ($validator->(@args)) {
                        
                            unshift @{$self->{errors}}, $error
                                if $self->report_failure;
                            
                            confess $error. " input, ". $self->errors_to_string
                                if ! $self->ignore_failure;
                            
                            return 0;
                            
                        }
                        
                    }
                    
                    # execute routine
                    my $return = $value->{using}->($self, @args);
                    
                    # run output validation
                    if ($output) {
                        
                        $validator = "ARRAY" eq ref $output ?
                            
                            # validate fields
                            sub { $self->validate(@{$output}) } :
                            
                            # validate profile
                            sub { $self->validate_profile($output, @_) } ;
                        
                        confess $error. " output, ". $self->errors_to_string
                            unless $validator->(@args);
                        
                    }
                    
                    return $return;
                    
                }
                
                else {
                    
                    confess "Error executing $key, no associates coderef";
                    
                }
                
            }
            
            return 0;
            
        }) unless $self->can($key); # I already can
        
    }
    
    # process parameters
    
    my %params = @_ ? @_ > 1 ? @_ : "HASH" eq ref $_[0] ? %{$_[0]} : () : ();
    
    while (my($attr, $value) = each (%params)) {
        
        $self->$attr($value);
        
    }
    
    # process plugins
    
    foreach my $plugin (keys %{$self->plugins}) {
        
        $plugin->new($self) if $plugin->can('new');
    
    }
    
    # process builders
    
    my $builders = $self->{config}->{BUILDERS};
    
    if ("ARRAY" eq ref $builders) {
        
        $_->($self) for @{$builders};
        
    }
    
    # initialize object
    
    $self->normalize;
    $self->apply_filters('pre') if $self->filtering;
    
    # end instantiation
    
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

    my ($name, $data) = @_;
    my $self = caller(0);

    return 0 unless ($name && "CODE" eq ref $data);
    
    no strict 'refs';

    $self->{config}->{PROFILES}->{$name} = $data;
    
    return $name, $data;

}

=head1 ATTRIBUTES, METHODS, AND MORE

This class encapsulates the functionality used to manipulate the environment of
the calling class. The engine-class is the role that provides all of the data
validation functionality, please see L<Validation::Class::Engine> for more
information on specific methods, and attributes.

=cut

1;