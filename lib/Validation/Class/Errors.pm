# ABSTRACT: Error Handling Object for Fields and Classes

package Validation::Class::Errors;

use strict;
use warnings;

# VERSION

use Carp 'confess';
use Validation::Class::Base 'has';

=head1 SYNOPSIS

    package SomeClass;
    
    use Validation::Class;
    
    package main;
    
    my $class = SomeClass->new;
    
    ...
    
    # errors at the class-level
    my $errors = $class->errors ;
    
    print $errors->to_string;
    
    # errors at the field-level
    my $field_errors = $user->fields->{name}->{errors} ;
    
    print $field_errors->to_string;
    
    1;

=head1 DESCRIPTION

Validation::Class::Errors is responsible for error handling in Validation::Class
derived classes on both the class and field levels respectively.

=cut

=method new

    my $self = Validation::Class::Errors->new;

=cut

sub new {
    
    bless [], shift
    
}

=method add_error

    $self = $self->add_error("houston, we have a problem", "this isn't cool");

=cut

sub add_error { goto &add_errors }

=method add_errors

    $self = $self->add_errors("houston, we have a problem", "this isn't cool");

=cut

sub add_errors {
    
    my ($self, @error_messages) = @_;
    
    my %seen = map { $_ => 1 } @{$self};
    
    push @{$self}, grep { !$seen{$_} } @error_messages;
    
    return $self;
    
}

=method all_errors

    my @list = $self->all_errors;

=cut

sub all_errors {
    
    return (@{$_[0]});
    
}

=method clear_errors

    $self = $self->clear_errors; 

=cut

sub clear_errors {
    
    my ($self) = @_;
    
    delete $self->[$_] for (0..($self->count_errors - 1)) ;
    
    return $self;
    
}

=method count_errors

    my $count = $self->count_errors; 

=cut

sub count_errors {
    
    return scalar(@{$_[0]});
    
}

=method each_error

    my $list = $self->each_error(sub{ ucfirst lc shift });

=cut

sub each_error {
    
    my ($self, $transformer) = @_;
    
    $transformer ||= sub {@_} ;
    
    return [ map {
        
        $_ = $transformer->($_)
        
    } @{$self} ]
    
}

=method error_list

    my $list = $self->error_list;

=cut

sub error_list {
    
    return [@{$_[0]}];
    
}

=method find_errors

    my @matches = $self->find_errors(qr/password/);

=cut

sub find_errors {
    
    my ($self, $pattern) = @_;
    
    return undef unless "REGEXP" eq uc ref $pattern;
    
    return ( grep { $_ =~ $pattern } $self->all_errors );
    
}

=method first_error

    my $item = $self->first_error;
    my $item = $self->first_error(qr/password/);

=cut

sub first_error {
    
    my ($self, $pattern) = @_;
    
    return $self->error_list->[0] unless "REGEXP" eq uc ref $pattern;
    
    return ( $self->find_errors($pattern) )[ 0 ];
    
}

=method get_error

    my $item = $self->get_error; # first error

=cut

sub get_error {
    
    my ($self) = @_;
    
    return $self->first_error;
    
}

=method get_errors

    my @list = $self->get_errors; # all errors

=cut

sub get_errors {
    
    my ($self) = @_;
    
    return $self->all_errors;
    
}

=method has_errors

    my $true = $self->has_errors; 

=cut

sub has_errors {
    
    my ($self) = @_;
    
    return $self->count_errors ? 1 : 0;
    
}

=method join_errors

    my $string = $self->join_errors; # returns "an error, another error"
    
    my $string = $self->join_errors($delimiter); 

=cut

sub join_errors {
    
    my ($self, $delimiter) = @_;
    
    $delimiter = ', ' unless defined $delimiter;
    
    return join $delimiter, $self->all_errors;
    
}

=method to_string

The to_string method stringifies the errors using the specified delimiter or ", "
(comma-space) by default. 

    my $string =  $self->to_string; # returns "an error, another error"
    
    my $string = $self->to_string($delimiter, sub { ucfirst lc shift });

=cut

sub to_string {
    
    my ($self, $delimiter, $transformer) = @_;
    
    $delimiter = ', ' unless defined $delimiter; # default delimiter is a comma-space
    
    $self->each_error($transformer) if $transformer;
    
    return $self->join_errors($delimiter);

}

1;