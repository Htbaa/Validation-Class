# ABSTRACT: Backwards-Compatibility Layer for Validation::Class::Engine

package Validation::Class::Backwards;

use strict;
use warnings;

# VERSION

use Carp 'confess';

=head1 SYNOPSIS

    package SomeClass;
    
    use Validation::Class;
    
    package main;
    
    my $class = SomeClass->new;
    
    ...
    
    1;

=head1 DESCRIPTION

Validation::Class::Backwards is responsible for providing depreciated
functionality to the L<Validation::Class::Prototype> layer whilst clearly
remaining seperate via namespacing.

Note: The methods described here will eventually become obsolete and cease to
exist. Please review the namespace occassionally and adjust your code
accordingly.

=cut

=method error

DEPRECIATING:

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

    # see Validation::Class::Error
    
    # set errors at the class-level
    return $self->errors->add_errors(...);
    
    # set an error at the field-level
    $self->fields->{$field_name}->{errors}->add_errors(...);

    # return all errors encountered
    my $list = $self->errors->error_list;

=cut

sub error {
    
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
            $field->{errors}->add_error($error);
            
            # add error to class-level errors
            $self->errors->add_error($error);
            
        }
        else {
            
            confess "Can't set error without proper field object, "
              . "field must be a hashref with name and value keys";
            
        }
    
    }
    
    # retrieve an error message on a particular field
    if ( @args == 1 ) {

        # add error to class-level errors    
        $self->errors->add_error($args[0]);
    
    }
    
    # return all class-level error messages
    return $self->errors->all_errors;
    
}

=method error_count

The error_count method returns the total number of error encountered from the 
last validation call.

    return $self->error_count();
    
    unless ($self->validate) {
        print "Found ". $self->error_count ." Errors";
    }

=cut

sub error_count {
    
    my ($self) = @_;
    
    return $self->errors->count_errors;
    
}

=method error_fields

The error_fields method returns a hashref of fields whose value is an arrayref
of error messages.

    unless ($self->validate) {
        my $bad_fields = $self->error_fields();
    }
    
    my $bad_fields = $self->error_fields('login', 'password');

=cut

sub error_fields {
    
    my ($self, @fields) = @_;
    
    my $error_fields = {};
    
    @fields = keys %{$self->fields} unless @fields;
    
    foreach my $name (@fields) {
        
        my $field = $self->fields->{$name};
        
        if ($field->{errors}->has_errors) {
            
            $error_fields->{$name} = $field->{errors}->error_list;
        
        }
        
    }
    
    return $error_fields;

}

=method errors_to_string

The errors_to_string method stringifies the error arrayref object using the
specified delimiter or ', ' by default. 

    return $self->errors_to_string("\n");
    return $self->errors_to_string(undef, sub{ ucfirst lc shift });
    
    unless ($self->validate) {
        return $self->errors_to_string;
    }

=cut

sub errors_to_string {
    
    my ($self, $delimiter, $transformer) = @_;
    
    return $self->errors->to_string($delimiter, $transformer);

}

1;