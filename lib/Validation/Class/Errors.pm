# ABSTRACT: Error Handling Object for Fields and Classes

package Validation::Class::Errors;

use strict;
use warnings;

# VERSION

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
    
    my $class = shift;
    
    my @arguments = @_ ? @_ > 1 ? @_ : "ARRAY" eq ref $_[0] ? @{$_[0]} : () : ();
    
    my $self = bless [], $class;
    
    $self->add($_) for @arguments;
    
    return $self;
    
}

=method add

    $self = $self->add("houston, we have a problem", "this isn't cool");

=cut

sub add {
    
    my ($self, @error_messages) = @_;
    
    return undef unless @error_messages;
    
    my %seen = map { $_ => 1 } @{$self};
    
    push @{$self}, grep { !$seen{$_} } @error_messages;
    
    return $self;
    
}

=method all

    my @list = $self->all;

=cut

sub all {
    
    return (@{$_[0]});
    
}

=method clear

    $self = $self->clear; 

=cut

sub clear {
    
    my ($self) = @_;
    
    delete $self->[($_ - 1)] for (1..$self->count) ;
    
    return $self;
    
}

=method count

    my $count = $self->count; 

=cut

sub count {
    
    return scalar(@{$_[0]});
    
}

=method each

    my $list = $self->each(sub{ ucfirst lc shift });

=cut

sub each {
    
    my ($self, $transformer) = @_;
    
    $transformer ||= sub {@_} ;
    
    return [ map {
        
        $_ = $transformer->($_)
        
    } @{$self} ]
    
}

=method list

    my $list = $self->list;

=cut

sub list {
    
    return [@{$_[0]}];
    
}

=method find

    my @matches = $self->find(qr/password/);

=cut

sub find {
    
    my ($self, $pattern) = @_;
    
    return undef unless "REGEXP" eq uc ref $pattern;
    
    return ( grep { $_ =~ $pattern } $self->all );
    
}

=method first

    my $item = $self->first;
    my $item = $self->first(qr/password/);

=cut

sub first {
    
    my ($self, $pattern) = @_;
    
    return $self->list->[0] unless "REGEXP" eq uc ref $pattern;
    
    return ( $self->find($pattern) )[ 0 ];
    
}

=method join

    my $string = $self->join; # returns "an error, another error"
    
    my $string = $self->join($delimiter); 

=cut

sub join {
    
    my ($self, $delimiter) = @_;
    
    $delimiter = ', ' unless defined $delimiter;
    
    return join $delimiter, $self->all;
    
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
    
    $self->each($transformer) if $transformer;
    
    return $self->join($delimiter);

}

1;