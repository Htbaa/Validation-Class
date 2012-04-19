# ABSTRACT: Simple Exporter for Validation::Class Classes

package Validation::Class::Exporter;

use 5.008001;

use strict;
use warnings;

# VERSION

=head1 SYNOPSIS

    package MyApp::Class;
    
    use Validation::Class;
    use Validation::Class::Exporter;
    
    Validation::Class::Exporter->apply_spec(
        routines => ['thing'], # export routines as is
        settings => [ ... ] # passed to the "load" method, see Validation::Class
    );
    
    has foo => 0;

    bld sub {
        
        shift->foo(1);
        
    };
    
    sub thing {
        
        my $args = pop;
        
        my $class = shift || caller;
        
        # routine as a keyword
        
        $class->{config}->{THING} = [$args];
        
    };
    
    package MyApp::Example;
    
    use MyApp::Class;
    
    thing ['this' => 'that'];
    
    package main;
    
    my $eg = MyApp::Example->new; # we have lift-off!!!

=head1 DESCRIPTION

This module (while experimental) encapsulates the exporting of keywords and
routines. It applies the L<Validation::Class> framework along with any keyword
routines and/or sub-routines specified with the apply_spec() method. It does
this by simply by copying the spec into the calling class.
 
To simplify writing exporter modules, C<Validation::Class::Exporter> also
imports C<strict> and C<warnings> into your exporter module, as well as into
modules that use it.

=cut

=method apply_spec

When you call this method, C<Validation::Class::Exporter> builds a custom
C<import> method on the calling class. The C<import> method will export the
functions you specify, and can also automatically export C<Validation::Class>
making the calling class a Validation::Class derived class.
 
This method accepts the following parameters:
 
=over 8
 
=item * routines => [ ... ]
 
This list of function I<names only> will be exported into the calling class
exactly as is, the functions can be used traditionally or as keywords so their
parameter handling should be configured accordingly.
 
=item * settings => [ ... ]
 
This list of key/value pair will be passed to the load method imported from
C<Validation::Class::load> and will be applied on the calling class.
 
This approach affords you some trickery in that you can utilize the load method
to apply the current class' configuration to the calling class' configuration,
etc.

=back
 
=cut

sub apply_spec {
    
    my ($this, %args) = @_;
    
    no strict 'refs';
    no warnings 'once';
    no warnings 'redefine';
    
    my $parent = caller(0);
    
    my @keywords = @{ $args{keywords} } if $args{keywords};

    my @routines = @{ $args{routines} } if $args{routines};
    
    my $settings = { @{ $args{settings} } } if $args{settings};
    
    *{"$parent\::import"} = sub {
       
        my $child = caller(0);
        
        *{"$child\::$_"} = *{"$parent\::$_"} for @keywords;
        
        *{"$child\::$_"} = *{"$parent\::$_"} for @routines;
        
        my $ISA  = "$child\::ISA";
        
        push @$ISA, 'Validation::Class';
        
        *{"$child\::$_"} = *{"Validation\::Class\::$_"}
            for @Validation::Class::EXPORT;
        
        strict->import;
        warnings->import;
        
        $child->load($settings) if $settings;
        
        return $child;
        
    };
    
    return $this;
    
}

1;