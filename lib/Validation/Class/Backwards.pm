# ABSTRACT: Backwards-Compatibility Layer for Validation::Class

package Validation::Class::Backwards;

use strict;
use warnings;

# VERSION

use Carp 'confess';

$ENV{'VALIDATION_CLASS_BC_WARNING'} = <<'WARNING'; # usage warning
The method you're attempting to use is (or will be) DEPRECATED.
WARNING

sub warning {
    warn $ENV{'VALIDATION_CLASS_BC_WARNING'}
        if $ENV{'VALIDATION_CLASS_BC_WARNING'}
}

=head1 SYNOPSIS

    package SomeClass;
    
    use Validation::Class;
    
    package main;
    
    my $class = SomeClass->new;
    
    ...
    
    1;

=head1 DESCRIPTION

Validation::Class::Backwards is responsible for providing deprecated
functionality to the L<Validation::Class::Prototype> layer whilst clearly
remaining separate via namespacing.

Note: The methods described here will eventually become obsolete and cease to
exist. Please review the namespace occasionally and adjust your code
accordingly. Using methods defined here will generate warnings unless you
unset the $ENV{'VALIDATION_CLASS_BC_WARNING'} environment variable.

=cut

=method error

DEPRECATING:

The error method is used to set and/or retrieve errors encountered during
validation. The error method with no parameters returns the error message object
which is an arrayref of error messages stored at class-level. 

    # set errors at the class-level
    return $self->error('this isnt cool', 'unknown somethingorother');
    
    # set an error at the field-level, using the field ref (not field name)
    $self->error($field_object, "i am your error message");

    # return all errors encountered/set as an arrayref
    my $all_errors = $self->error();

RECOMMENDED:

    # see Validation::Class::Errors
    
    # set errors at the class-level
    return $self->errors->add(...);
    
    # set an error at the field-level
    $self->fields->{$field_name}->{errors}->add(...);

    # return all errors encountered
    my $list = $self->errors->list;

=cut

sub error { warning();
    
    my ( $self, @args ) = @_;

    # set an error message on a particular field
    if ( @args == 2 ) {
    
        # set error message
        my ( $field, $error ) = @args;
        
        # field must be a reference (hashref) to a field object
        if ( ref($field) && ( !ref($error) && $error ) ) {
        
            # temporary, may break stuff
            $error = $field->{error} if defined $field->{error};
            
            # add error to field-level errors
            $field->{errors}->add($error);
            
            # add error to class-level errors
            $self->errors->add($error);
            
        }
        else {
            
            confess "Can't set error without proper field object, "
              . "field must be a hashref with name and value keys";
            
        }
    
    }
    
    # retrieve an error message on a particular field
    if ( @args == 1 ) {

        # add error to class-level errors    
        $self->errors->add($args[0]);
    
    }
    
    # return all class-level error messages
    return $self->errors->all;
    
}

1;
