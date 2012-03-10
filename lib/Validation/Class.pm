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

use Validation::Class::Engine; # used-as-role, see new

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

See the ignore_failure and report_failure switch to control how method failures
are handled.

    package MyApp::User;
    
    use Validation::Class;
    
    method 'register' => {
    
        input => [qw/-name +email -login +password/],
        using => sub {
        
            my ($self, @args) = @_;
            # ...
        
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
(or "needs") variable whose value is either an arrayref of fields to be validated,
or a constant value which matches a validation profile name. The hashref must
also have a "using" variable whose value is a coderef which will be executed upon
successfully validating the input. Whether and what the method returns is yours
to decide.

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
            my $reqid = $value->{needs} ? 'needs' : 'input';
            
            if ($value->{$reqid}) {
            
                my $validator =
                    "ARRAY" eq ref $value->{$reqid} ?
                        sub { $self->validate(@{$value->{$reqid}}) } :
                        sub { $self->validate_profile($value->{$reqid}, @_) } ;
                
                if ($validator->(@args)) {
                    
                    return $value->{using}->($self, @args) ;
                    
                }
                
                else {
                    
                    my $error = "method $key failed to validate";
                    
                    unshift @{$self->{errors}}, $error if $self->report_failure;
                    
                    confess $self->errors_to_string unless $self->ignore_failure;
                    
                }
                
                return 0;
            
            }
            
            else {
                
                if ("CODE" eq ref $value->{using}) {
                    
                    return $value->{using}->($self, @args) ;
                    
                }
                
                else {
                    
                    confess "Error executing method $key, no associates coderef";
                    
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


=head2 THE PROFILE KEYWORD



=cut

=head2 THE METHOD KEYWORD



=cut



=head1 FILTERING INCOMING DATA

Validation::Class supports pre/post filtering but is configured to pre-filter
incoming data. This means that based upon the filtering options supplied within
the individual fields, filtering will happen before validation (technically at
instantiation and again just before validation). As expected, this is configurable
via the filtering attribute.

A WORD OF CAUTION: Validation::Class is configured to pre-filter incoming data
which boosts application security and is best used with passive filtering 
(e.g. converting character case - filtering which only alters the input in
predictable ways), versus aggressive filtering (e.g. formatting a telephone
number) which completely and permanently changes the incoming data ... so much
so that if the validation still fails ... errors that are reported may not
match the data that was submitted.

If you're sure you'd rather employ aggressive filtering, I suggest setting
the filtering attribute to 'post' for post-filtering or setting it to null
and applying the filters manually by calling the apply_filters() method.

=head1 AUTO-SERIALIZATION/DESERIALIZATION

Validation::Class supports automatic serialization and deserialization of
parameters with complex data structures which means that you can set a parameter
as an arrayref or hashref of nested data structures and validate against them, 
likewise you can set a parameters using parameter names which are serialized
string representations of the keys within the complex structure you wish to set
and validate against. The serialization rules are as documented in L<Hash::Flatten>.

The following is an example of that:

    my $params = {
        user => {
            login => 'admin',
            password => 'pass'
        }
    };
    
    my $rules = MyApp::Validation->new(params => $params);
    
    # or
    
    my $params = {
        'user.login' => 'admin',
        'user.password' => 'pass'
    };
    
    my $rules = MyApp::Validation->new(params => $params);
    
    # field definition using field('user.login', ...)
    # and field('user.password', ...) will match against the parameters above
    
    # after filtering, validation, etc ... return your params as a hashref if
    # needed
    
    my $params = $rules->get_params_hash;

=head1 SEPARATION OF CONCERNS

For larger applications where a single validation class might become cluttered
and inefficient, Validation::Class comes equipped to help you separate your
validation rules into separate classes.

The idea is that you'll end up with a main validation class (most likely empty)
that will simply serve as your point of entry into your relative (child)
classes. The following is an example of this:

    package MyVal::User;
    use Validation::Class;
    
    field name => { ... };
    field email => { ... };
    field login => { ... };
    field password => { ... };
    
    package MyVal::Profile;
    use Validation::Class;
    
    field age => { ... };
    field sex => { ... };
    field birthday => { ... };
    
    package MyVal;
    use Validation::Class;
    
    load { classes => 1 };
    
    package main;
    
    my $rules = MyVal->new(params => $params);
    my $user = $rules->class('user');
    my $profile = $rules->class('profile');
    
    ...
    
    1;

=cut

=head1 DEFAULT FIELD/MIXIN DIRECTIVES

    package MyApp::Validation;
    use Validation::Class;
    
    # a validation template
    mixin '...'  => {
        # mixin directives here
        ...
    };
    
    # a validation rule
    field '...'  => {
        # field directives here
        ...
    };
    
    1;
    
When building a validation class, the first encountered and arguably two most
important keyword functions are field() and mixin(), which are used to declare
their respective properties. A mixin() declares a validation template where
its properties are intended to be copied within field() declarations which
declares validation rules, filters and other properties.

Both the field() and mixin() declarations/functions require two parameters, the
first being a name, used to identify the declaration and to be matched against
incoming input parameters and the second being a hashref of key/value pairs.
The key(s) within a declaration are commonly referred to as directives.

The following is a list of default directives which can be used in field/mixin
declarations:

=cut

=head2 alias

The alias directive is useful when many different parameters with different
names can be validated using a single rule. E.g. The paging parameters in a
webapp may take on different names but require the same validation.

    # the alias directive
    field 'pager'  => {
        alias => ['page_user_list', 'page_other_list']
        ...
    };

=cut

=head2 default

The default directive is used as a default value for a field to be used
when a matching parameter is not present.

    # the default directive
    field 'quantity'  => {
        default => 1,
        ...
    };

=cut

=head2 error/errors

The error/errors directive is used to replace the system generated error
messages when a particular field doesn't validate. If a field fails multiple
directives, multiple errors will be generated for the same field. This may not
be desirable, the error directive overrides this behavior and only the specified
error is registered and displayed.

    # the error(s) directive
    field 'foobar'  => {
        errors => 'Foobar failed processing, Wtf?',
        ...
    };

=cut

=head2 filtering

The filtering directive is used to control when field filters are applied. The
default recognized values are pre/post. A value of 'pre' instructs the validation
class to apply the field's filters at instantiation and before validation whereas
a value of 'post' instructs the validation class to apply the field's filters
after validation. Alternatively, a value of undef or '' will bypass filtering
altogether.

    # the filtering directive
    field 'foobar'  => {
        filtering => 'post',
        ...
    };

=cut

=head2 label

The label directive is used as a user-friendly reference when the field name
is a serialized hash key or just plain ugly.

    # the label directive
    field 'hashref.foo.bar'  => {
        label => 'Foo Bar',
        ...
    };

=cut

=head2 mixin

The mixin directive is used to create a template of directives to be applied to
other fields.

    mixin 'ID' => {
        required => 1,
        min_length => 1,
        max_length => 11
    };

    # the mixin directive
    field 'user.id'  => {
        mixin => 'ID',
        ...
    };

=cut

=head2 mixin_field

The mixin directive is used to copy all directives from an existing field
except for the name, label, and validation directives.

    # the mixin_field directive
    field 'foobar'  => {
        label => 'Foo Bar',
        required => 1
    };
    
    field 'barbaz'  => {
        mixin_field => 'foobar',
        label => 'Bar Baz',
        ...
    };

=cut

=head2 name

The name directive is used *internally* and cannot be changed.

    # the name directive
    field 'thename'  => {
        ...
    };

=cut

=head2 required

The required directive is an important directive but can be misunderstood.
The required directive is used to ensure the submitted parameter exists and
has a value. If the parameter is never submitted, the directive is effectively
skipped. This directive can be thought of as the "must-have-a-value-if-exists"
directive.

    # the required directive
    field 'foobar'  => {
        required => 1,
        ...
    };
    
    # fail
    my $rules = MyApp::Validation->new(params => {  });
    $rules->validate('foobar');
    
    # fail
    my $rules = MyApp::Validation->new(params => { foobar => '' });
    $rules->validate('foobar');
    
    # pass
    my $rules = MyApp::Validation->new(params => {  foobar => 'Nice' });
    $rules->validate('foobar');
    
See the toggle functionality within the validate() method. This method allows
you to temporarily alter whether a field is required or not.

=cut

=head2 validation

The validation directive is a coderef used add additional custom validation to
the field. The coderef must return true (to pass) or false (to fail). Custom
error messages can be set from within the coderef so make sure they are set
based on appropriate logic as the registration of error message are not
contingent on the success or failure of the routine. 

    # the validation directive
    field 'login'  => {
        validation => sub {
            my ($self, $this_field, $all_params) = @_;
            return 0 unless $this_field->{value};
            return $this_field->{value} eq 'admin' ? 1 : 0;
        },
        ...
    };

=cut

=head2 value

The value directive is used internally to store the field's matching parameter's
value. This value can be set in the definition but SHOULD NOT be used as a
default value unless you're sure no parameter will overwrite it during run-time.
If you need to set a default value, see the default directive.

    # the value directive
    field 'quantity'  => {
        value => 1,
        ...
    };

=cut

=head1 DEFAULT FIELD/MIXIN FILTER DIRECTIVES

=head2 filters

The filters directive is used to correct, alter and/or format the
values of the matching input parameter. Note: Filtering is applied before
validation. The filter directive can have multiple filters (even a coderef)
in the form of an arrayref of values.

    # the filter(s) directive
    field 'text'  => {
        filters => [qw/trim strip/ => sub {
            $_[0] =~ s/\D//g;
        }],
        ...
    };
    
The following is a list of default filters that may be used with the filter
directive:

=cut

=head3 alpha

The alpha filter removes all non-Alphabetic characters from the field's value.

    field 'foobar'  => {
        filter => 'alpha',
    };
    
=cut

=head3 alphanumeric

The alpha filter removes all non-Alphabetic and non-Numeric characters from the
field's value.

    field 'foobar'  => {
        filter => 'alphanumeric',
    };
    
=cut

=head3 capitalize

The capitalize filter attempts to capitalize the first word in each sentence,
where sentences are separated by a period and space, within the field's value.

    field 'foobar'  => {
        filter => 'capitalize',
    };
    
=cut

=head3 decimal

The decimal filter removes all non-decimal-based characters from the field's
value. Allows only: decimal, comma, and numbers.

    field 'foobar'  => {
        filter => 'decimal',
    };
    
=cut

=head3 numeric

The numeric filter removes all non-numeric characters from the field's
value.

    field 'foobar'  => {
        filter => 'numeric',
    };
    
=cut

=head3 strip

As with the trim filter the strip filter removes leading and trailing
whitespaces from the field's value and additionally removes multiple whitespaces
from between the values characters.

    field 'foobar'  => {
        filter => 'strip',
    };
    
=cut

=head3 titlecase

The titlecase filter converts the field's value to titlecase by capitalizing the
first letter of each word.

    field 'foobar'  => {
        filter => 'titlecase',
    };
    
=cut

=head3 trim

The trim filter removes leading and trailing whitespace from the field's value.

    field 'foobar'  => {
        filter => 'trim',
    };
    
=cut

=head3 uppercase

The uppercase filter converts the field's value to uppercase.

    field 'foobar'  => {
        filter => 'uppercase',
    };
    
=cut

=head1 DEFAULT FIELD/MIXIN VALIDATOR DIRECTIVES

    package MyApp::Validation;
    
    use Validation::Class;
    
    # a validation rule with validator directives
    field 'telephone_number'  => {
        length => 14,
        pattern => '(###) ###-####',
        ...
    };
    
    1;
    
Validator directives are special directives with associated validation code that
is used to validate common use cases such as "checking the length of a parameter",
etc.

The following is a list of the default validators which can be used in field/mixin
declarations:

=cut

=head2 between

    # the between directive
    field 'foobar'  => {
        between => '1-5',
        ...
    };

=cut

=head2 depends_on

    # the depends_on directive
    field 'change_password'  => {
        depends_on => ['password', 'password_confirm'],
        ...
    };

=cut

=head2 length

    # the length directive
    field 'foobar'  => {
        length => 20,
        ...
    };

=cut

=head2 matches

    # the matches directive
    field 'this_field'  => {
        matches => 'another_field',
        ...
    };

=cut

=head2 max_alpha

    # the max_alpha directive
    field 'password'  => {
        max_alpha => 30,
        ...
    };

=cut

=head2 max_digits

    # the max_digits directive
    field 'password'  => {
        max_digits => 5,
        ...
    };

=cut

=head2 max_length

    # the max_length directive
    field 'foobar'  => {
        max_length => '...',
        ...
    };

=cut

=head2 max_sum

    # the max_sum directive
    field 'vacation_days'  => {
        max_sum => 5,
        ...
    };

=cut

=head2 max_symbols

    # the max_symbols directive
    field 'password'  => {
        max_symbols => 1,
        ...
    };

=cut

=head2 min_alpha

    # the min_alpha directive
    field 'password'  => {
        min_alpha => 2,
        ...
    };

=cut

=head2 min_digits

    # the min_digits directive
    field 'password'  => {
        min_digits => 1,
        ...
    };

=cut

=head2 min_length

    # the min_length directive
    field 'foobar'  => {
        min_length => '...',
        ...
    };

=cut

=head2 min_sum

    # the min_sum directive
    field 'vacation_days'  => {
        min_sum => 0,
        ...
    };

=cut

=head2 min_symbols

    # the min_symbols directive
    field 'password'  => {
        min_symbols => 0,
        ...
    };

=cut

=head2 options

    # the options directive
    field 'status'  => {
        options => 'Active, Inactive',
        ...
    };

=cut

=head2 pattern

    # the pattern directive
    field 'telephone'  => {
        # simple pattern
        pattern => '### ###-####',
        ...
    };
    
    field 'country_code'  => {
        # simple pattern
        pattern => 'XX',
        filter  => 'uppercase'
        ...
    };
    
    field 'complex'  => {
        # regex pattern
        pattern => qr/[0-9]+\,\s\.\.\./,
        ...
    };

=cut

=head1 THE VALIDATION CLASS

The following is an example of how to use your constructed validation class in
other code, .e.g. Web App Controller, etc.

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    unless ($input->validate('field1','field2')){
        return $input->errors_to_string;
    }
    
Feeling lazy? Have your validation class automatically find the appropriate fields
to validate against (params must match field names).

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    unless ($input->validate){
        return $input->errors_to_string;
    }
    
You can define an alias to automatically map a parameter to a validation field
whereby a field definition will have an alias attribute containing an arrayref
of alternate parameters that can be matched against passed-in parameters.

    package MyApp::Validation;
    
    field 'foo.bar' => {
        ...,
        alias => [
            'foo',
            'bar',
            'baz',
            'bax'
        ]
    };

    use MyApp::Validation;
    
    my  $input = MyApp::Validation->new(params => { foo => 1 });
    unless ($input->validate(){
        return $input->errors_to_string;
    }

=cut

=head2 new

The new method instantiates and returns an instance of your validation class.

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new;
    $input->params($params);
    ...
    
    my $input = MyApp::Validation->new(params => $params);
    ...

=cut

=head1 VALIDATION CLASS ATTRIBUTES

=head2 ignore_failure

The ignore_failure boolean determines whether your application will live or die
upon failing to validate a self-validating method defined using the method
keyword. This is on (1) by default, method validation failures will set errors
and can be determined by checking the error stack using one of the error message
methods. If turned off, the application will die and confess on failure.

    my $self = MyApp::Validation->new(params => $params, ignore_failure => 0);
    $self->ignore_failure(1);
    ...

=cut

=head2 ignore_unknown

The ignore_unknown boolean determines whether your application will live or die
upon encountering unregistered field directives during validation. This is off
(0) by default, attempts to validate unknown fields WILL cause the program to die.

    my $self = MyApp::Validation->new(params => $params, ignore_unknown => 1);
    $self->ignore_unknown(1);
    ...

=cut

=head2 fields

The fields attribute returns a hashref of defined fields, filtered and merged
with their parameter counterparts.

    my $self = MyApp::Validation->new(fields => $fields);
    my $fields = $self->fields();
    ...

=cut

=head2 filtering

The filtering attribute (by default set to 'pre') controls when incoming data
is filtered. Setting this attribute to 'post' will defer filtering until after
validation which allows any errors messages to report errors based on the
unaltered data. Alternatively, setting the filtering attribute to '' or undef
will bypass all filtering unless explicitly defined at the field-level.

    my $self = MyApp::Validation->new(filtering => 'post');
    $self->validate();
    ...

=cut

=head2 filters

The filters attribute returns a hashref of pre-defined filter definitions.

    my $filters = $self->filters();
    ...

=cut

=head2 hash_inflator

The hash_inflator value determines how the hash serializer (inflation/deflation)
behaves. The value must be a hashref of L<Hash::Flatten/OPTIONS> options. Purely
for the sake of consistency, you can use lowercase keys (with underscores) which
will be converted to camel-cased keys before passed to the serializer.

    my $self = MyApp::Validation->new(
        hash_inflator => {
            hash_delimiter => '/',
            array_delimiter => '//'
        }
    );
    ...

=cut

=head2 mixins

The mixins attribute returns a hashref of defined validation templates.

    my $mixins = $self->mixins();
    ...

=cut

=head2 params

The params attribute gets/sets the parameters to be validated.

    my $input = {
        ...
    };
    
    my $self = MyApp::Validation->new(params => $input);
    
    $self->params($input);
    my $params = $self->params();
    
    ...

=cut

=head2 report_failure

The report_failure boolean determines whether your application will report
self-validating method failures as class-level errors. This is off (0) by default,
if turned on, an error messages will be generated and set at the class-level
specifying the method which failed in addition to the existing messages.

    my $self = MyApp::Validation->new(params => $params,
    ignore_failure => 1, report_failure => 1);
    $self->report_unknown(0);
    ...

=cut

=head2 report_unknown

The report_unknown boolean determines whether your application will report
unregistered fields as class-level errors upon encountering unregistered field
directives during validation. This is off (0) by default, attempts to validate
unknown fields will NOT be registered as class-level variables.

    my $self = MyApp::Validation->new(params => $params,
    ignore_unknown => 1, report_unknown => 1);
    $self->report_unknown(1);
    ...

=cut

=head2 stashed

The stashed attribute represents a list of field names stored to be used in
validation later. If the stashed attribute contains a list you can omit
arguments to the validate method. 

    $self->stashed([qw/this that .../]);

=cut

=head1 VALIDATION CLASS METHODS

=head2 apply_filters

The apply_filters method (usually called automatically based on the filtering
attribute) can be used to run the currently defined parameters through the
filters defined in the fields.

    my $rules = MyVal->new(filtering => '', params => $params);
    
    if ($rules->validate) {
        $rules->apply_filters;
    }
    else {
        print $rules->errors_to_string;
        # print errors on unaltered parameters
    }

=cut

=head2 class

The class method returns a new initialize child validation class under the
namespace of the calling class that issued the load_classes() method call.
Existing parameters and configuration options are passed to the child class's
constructor. All attributes can be easily overwritten using the attribute's
accessors on the child class. Also, you may prevent/override arguments from
being copy to the new child class object by supplying the them as arguments to
this method.

The class method is also quite handy in that it will detect parameters that are
prefixed with the name of the class being fetched, and adjust the matching rule
(if any) to allow validation to occur.

    package MyVal;
    use Validation::Class;
    
    load {
        classes => 1 # load child classes e.g. MyVal::*
    };
    
    package main;
    
    my $rules = MyVal->new(params => $params);
    
    my $kid1 = $rules->class('Child'); # loads MyVal::Child;
    my $kid2 = $rules->class('StepChild'); # loads MyVal::StepChild;
    
    my $kid3 = $rules->class('child'); # loads MyVal::Child;
    my $kid4 = $rules->class('step_child'); # loads MyVal::StepChild;
    
    # INTELLIGENTLY DETECTING AND MAP PARAMS TO CHILD CLASS
    my $params = {
        'my.name'    => 'Guy Friday',
        'child.name' => 'Guy Friday Jr.'
    };
    
    $rules->class('child'); # child field *name* mapped to param *child.name*
    
    # WITHOUT COPYING PARAMS FROM MyVal
    my $kid5 = $rules->class('child', params => {}); # .. etc
    
    1;

=cut

=head2 clear_queue

The clear_queue method resets the queue container, see the queue method for more
information on queuing fields to be validated. The clear_queue method has yet
another useful behavior in that it can assign the values of the queued
parameters to the list it is passed, where the values are assigned in the same
order queued.

    my $rules = MyVal->new(params => $params);
    
    $rules->queue(qw(name +email +login +password));
    
    unless ($rules->validate) {
        return $rules->errors_to_string;
    }
    
    $rules->clear_queue(my($name, $email));
    
    1;

=cut

=head2 clone

The clone method is used to create new fields (rules) from existing fields
on-the-fly. This is useful when you have a variable number of parameters being
validated that can share existing validation rules. E.g., a web-form on a user's
profile page may have dynamically created input boxes for the person's phone
numbers allowing the user to add additional parameters to the web-form as
needed, in that case as opposed to having multiple validation rules hardcoded
for each parameter, you could hardcode one single rule and clone the rule at
run-time.

    package MyVal;
    use Validation::Class;
    
    field phone => { required => 1 };
    
    package main;
    
    my $rules = MyVal->new(params => $params);
    
    # clone phone rule at run-time to validate dynamically created parameters
    $rules->clone('phone', 'phone2', { label => 'Other Phone', required => 0 });
    $rules->clone('phone', 'phone3', { label => 'Third Phone', required => 0 });
    $rules->clone('phone', 'phone4', { label => 'Forth Phone', required => 0 });
    
    $rules->validate(qw/phone phone2 phone3 phone4/);
    
    1;

=cut

=head2 error

The error method is used to set and/or retrieve errors encountered during
validation. The error method with no parameters returns the error message object
which is an arrayref of error messages stored at class-level. 

    # set errors at the class-level
    return $self->error('this isnt cool', 'unknown somethingorother');
    
    # set an error at the field-level, using the field ref (not field name)
    $self->error($field_object, "i am your error message");

    # return all errors encountered/set as an arrayref
    my $all_errors = $self->error();
    
    # return all error for a specific field, ... see the get_errors() method
    my @errors = $self->get_errors('field_name');

=cut

=head2 error_count

The error_count method returns the total number of error encountered from the 
last validation call.

    return $self->error_count();
    
    unless ($self->validate) {
        print "Found ". $self->error_count ." Errors";
    }

=cut

=head2 error_fields

The error_fields method returns a hashref of fields whose value is an arrayref
of error messages.

    unless ($self->validate) {
        my $bad_fields = $self->error_fields();
    }
    
    my $bad_fields = $self->error_fields('login', 'password');

=cut

=head2 errors_to_string

The errors_to_string method stringifies the error arrayref object using the
specified delimiter or ', ' by default. 

    return $self->errors_to_string("<br/>\n");
    return $self->errors_to_string("<br/>\n", sub{ uc shift });
    
    unless ($self->validate) {
        return $self->errors_to_string;
    }

=cut

=head2 get_errors

The get_errors method returns the list of class-level error set on the current
class or a list of errors from the specified fields.

    my @errors = $self->get_errors();
    my @lp_errors = $self->get_errors('login', 'password');

=cut

=head2 get_params

The get_params method returns the values (in list form) of the parameters
specified.

    if ($self->validate) {
        my $name_a = $self->get_params('name');
        my ($name_b, $email, $login, $password) =
            $self->get_params(qw/name email login password/);
        
        # you should note that if the params dont exist they will return undef
        # ... meaning you should check that it exists before checking its value
        # e.g.
        
        if (defined $name) {
            if ($name eq '') {
                print 'name parameter was passed but was empty';
            }
        }
        else {
            print 'name parameter was never submitted';
        }
    }

=cut

=head2 get_params_hash

If your fields and parameters are designed with complex hash structures, the
get_params_hash method returns the deserialized hashref of specified parameters
based on the the default or custom configuration of the hash serializer
L<Hash::Flatten>.

    my $params = {
        'user.login' => 'member',
        'user.password' => 'abc123456'
    };
    
    if ($self->validate(keys %$params)) {
        my $params = $self->get_params_hash;
        print $params->{user}->{login};
    }

=cut

=head2 param

The param method returns a single parameter by name.

    if ($self->param('chng_pass')) {
        $self->validate('password_confirmation');
    }

=cut

=head2 queue

The queue method is a convenience method used specifically to append the
stashed attribute allowing you to *queue* field to be validated. This method
also allows you to set fields that must always be validated. 

    # conditional validation flow WITHOUT the queue method
    # imagine a user profile update action
    
    my $rules = MyApp::Validation->new(params => $params);
    my @fields = qw/name login/;
    
    push @fields, 'email_confirm' if $rules->param('chg_email');
    push @fields, 'password_confirm' if $rules->param('chg_pass');
    
    ... if $rules->validate(@fields);
    
    # conditional validation WITH the queue method
    
    my $rules = MyApp::Validation->new(params => $params);
    
    $rules->queue(qw/name login/);
    $rules->queue(qw/email_confirm/) if $rules->param('chg_email');
    $rules->queue(qw/password_confirm/) if $rules->param('chg_pass');
    
    ... if $rules->validate();
    
    # set fields that must ALWAYS be validated
    # imagine a simple REST server
    
    my $rules = MyApp::Validation->new(params => $params);
    
    $rules->queue(qw/login password/);
    
    if ($request eq '/resource/:id') {
        
        if ($rules->validate('id')) {
            
            # validated login, password and id
            ...
        }
    }

=cut

=head2 reset

The reset method clears all errors, fields and stashed field names, both at the
class and individual field levels.

    $self->reset();

=cut

=head2 reset_errors

The reset_errors method clears all errors, both at the class and individual
field levels. This method is called automatically every time the validate()
method is triggered.

    $self->reset_errors();

=cut

=head2 reset_fields

The reset_fields method clears all errors and field values, both at the class
and individual field levels. This method is executed automatically at
instantiation.

    $self->reset_fields();

=cut

=head2 sanitize

The sanitize method executes a set of routines that reset the parameter
environment filtering any parameters present. This method is executed
automatically at instantiation and validation. 

    $self->sanitize();

=cut

=head2 set_errors

The set_errors method pushes its arguments (error messages) onto the class-level
error stack of the current class.

    my $count = $self->set_errors('Oops', 'OMG', 'WTF');

=cut

=head2 set_method

The set_method method conveniently creates a method on the calling class, this
method is primarily intended to be used during instantiation of a plugin during
instantiation of the validation class.

Additionally, method names are flattened, e.g. ThisPackage will be converted to
this_package for convenience and consistency.

    my $sub = $self->set_method(__PACKAGE__ => sub { ... });

=cut

=head2 set_params_hash

Depending on how parameters are being input into your application, if your
input parameters are already complex hash structures, The set_params_hash method
will set and return the serialized version of your hashref based on the the
default or custom configuration of the hash serializer L<Hash::Flatten>.

    my $params = {
        user => {
            login => 'member',
            password => 'abc123456'
        }
    };
    
    my $serialized_params = $self->set_params_hash($params);

=cut

=head2 stash

The stash method provides a container for context/instance specific information.
The stash is particularly useful when custom validation routines require insight
into context/instance specific operations.

    package MyApp::Validation;
    
    use Validation::Class;
    
    fld 'email' => {
        validation => sub {
            my $db = shift->stash->{database};
            my $this = shift;
            
            return $db->find('email' => $this->{value}) ? 0 : 1 ; # email exists
        }
    };
    
    package main;
    
    $self->stash( { database => $dbix_object } );
    $self->stash( ftp => $net_ftp, database => $dbix_object );
    
    ...

=cut

=head2 validate

The validate method returns true/false depending on whether all specified fields
passed validation checks. 

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    
    # validate specific fields
    unless ($input->validate('field1','field2')){
        return $input->errors_to_string;
    }
    
    # validate fields based on a regex pattern
    unless ($input->validate(qr/^field(\d+)?/)){
        return $input->errors_to_string;
    }
    
    # validate existing parameters, if no parameters exist,
    # validate all fields ... which will return true unless field(s) exist
    # with a required directive
    unless ($input->validate()){
        return $input->errors_to_string;
    }
    
    # validate all fields period, obviously
    unless ($input->validate(keys %{$input->fields})){
        return $input->errors_to_string;
    }
    
    # validate specific parameters (by name) after mapping them to other fields
    my $parameter_map = {
        user => 'hey_im_not_named_login',
        pass => 'password_is_that_really_you'
    };
    unless ($input->validate($parameter_map)){
        return $input->errors_to_string;
    }
    
Another cool trick the validate() method can perform is the ability to temporarily
alter whether a field is required or not during run-time. This functionality is
often referred to as the *toggle* function.

This method is important when you define a field (or two or three) as required
or non and want to change that per validation. This is done by calling the
validate() method with a list of fields to be validated and prefixing the
target fields with a plus or minus as follows:

    use MyApp::Validation;
    
    my $input = MyApp::Validation->new(params => $params);
    
    # validate specific fields, force name, email and phone to be required
    # regardless of the field definitions directives ... and force the age, sex
    # and birthday to be optional
    
    my @spec = qw(+name +email +phone -age -sex -birthday);
    
    unless ($input->validate(@spec)){
        return $input->errors_to_string;
    }

=cut

=head2 validate_profile

The validate_profile method executes a stored validation profile, it requires a
profile name and can be passed additional parameters which get forwarded into the
profile routine in the order received.

    unless ($self->validate_profile('password_change')) {
        die $self->errors_to_string;
    }
    
    unless ($self->validate_profile('email_change', $dbi_handle)) {
        die $self->errors_to_string;
    }

=cut

1;