# ABSTRACT: Field Object for Validation::Class Classes

package Validation::Class::Field;

use strict;
use warnings;

# VERSION

use Carp 'confess';
use Validation::Class::Base 'has';
use Validation::Class::Prototype;

my $directives = Validation::Class::Prototype->configuration->{DIRECTIVES};

while (my($dir, $cfg) = each %{$directives}) {
    
    if ($cfg->{field}) {
        
        next if $dir =~ s/[^a-zA-Z0-9\_]/\_/g;
        
        # create accessors from default configuration (once)
        has $dir => undef unless grep { $dir eq $_ } qw(errors); 
        
    }
    
}

=head1 SYNOPSIS

    package SomeClass;
    
    use Validation::Class;
    
    package main;
    
    my $class = SomeClass->new;
    
    ...
    
    my $field = $class->get_field('some_field_name');
    
    $field->apply_filters;
    
    $field->validate; # validate this only
    
    $field->errors->count; # field-level errors
    
    1;

=head1 DESCRIPTION

Validation::Class::Field is responsible for field data handling in
Validation::Class derived classes, performs functions at the field-level only.

This class automatically creates attributes for all acceptable field directives
as listed under L<Validation::Class::Prototype/DIRECTIVES>.

=cut

=attribute errors

The errors attribute is a L<Validation::Class::Errors> object.

=cut

has 'errors' => sub { Validation::Class::Errors->new };

=method new

    my $self = Validation::Class::Field->new({
        name => 'some_field_name'
    });

=cut

sub new {
    
    my ($class, $config) = @_;
    
    confess "Can't create a new field object without a name attribute"
        unless $config->{name};
    
    my $self = bless $config, $class;
    
    delete $self->{errors} if exists $self->{errors};
    
    $self->errors; # initialize if not already
    
    return $self;
    
}

1;