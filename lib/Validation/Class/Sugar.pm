# DSL For Defining Input Validation Rules

use strict;
use warnings;

package Validation::Class::Sugar;

# VERSION

use Scalar::Util qw(blessed);
use Carp qw(confess);

use Moose::Role;
use Moose::Exporter;
use Module::Find;

Moose::Exporter->setup_import_methods(
    with_meta => [qw(
        dir
        directive
        fld
        field
        flt
        filter
        mxn
        mixin
        pro
        profile
        
        load
        load_classes
        load_plugins
    )]
);

sub dir { goto &directive }
sub directive {
    my ($meta, $name, $data) = @_;
    my $config = find_or_create_cfg_attribute($meta);
    
    confess("config attribute not present") unless blessed($config);

    return undef unless ($name && $data);
        
    my $CFG = $config->profile;
       $CFG->{DIRECTIVES}->{$name} = {
            mixin     => 1,
            field     => 1,
            validator => $data
       };
    
    return 'directive', $name, $data;
}

sub fld { goto &field }
sub field {
    my ($meta, $name, $data) = @_;
    my $config = find_or_create_cfg_attribute($meta);
    
    confess("config attribute not present") unless blessed($config);

    return undef unless ($name && $data);
    
    my $CFG = $config->profile;
       $CFG->{FIELDS}->{$name} = $data;
       $CFG->{FIELDS}->{$name}->{errors} = [];
    
    return 'field', $name, $data;
}

sub flt { goto &filter }
sub filter {
    my ($meta, $name, $data) = @_;
    my $config = find_or_create_cfg_attribute($meta);
    
    confess("config attribute not present") unless blessed($config);

    return undef unless ($name && $data);
    
    my $CFG = $config->profile;
       $CFG->{FILTERS}->{$name} = $data;
    
    return 'filter', $name, $data;
}

sub load {
    my ($meta, $data) = @_;
    my $caller = caller(1); # hackaroni toni
    
    $caller->load_classes() if $data->{classes};
    $caller->load_plugins(@{$data->{plugins}}) if $data->{plugins};
}

sub load_classes {
    my ($meta, $parent) = @_;
    my $rels = $meta->find_attribute_by_name('relatives');
    my $rels_map = {};
    
    # load class children and create relationship map (hash)
    foreach my $child (usesub $parent) {
        my $nickname  = $child;
           $nickname  =~ s/^$parent//;
           $nickname  =~ s/^:://;
           $nickname  =~ s/([a-z])([A-Z])/$1\_$2/g;
           
        my $quickname = $child;
           $quickname =~ s/^$parent//;
           $quickname =~ s/^:://;
           
        $rels_map->{lc $nickname} = $child;
        $rels_map->{$quickname}   = $child;
    }
    
    $rels->{default} = sub {
        return $rels_map;
    };
    
    return $rels_map;
}

sub load_plugins {
    my ($meta, $class, @plugins) = @_;
    my $config = find_or_create_cfg_attribute($meta);
    
    confess("config attribute not present") unless blessed($config);
    
    foreach my $plugin (@plugins) {
        if ($plugin !~ /^\+/) {
            $plugin = "Validation::Class::Plugin::$plugin";
        }
        
        $plugin =~ s/^\+//;
        
        # require plugin
        my $file = $plugin; $file =~ s/::/\//g; $file .= ".pm";
        eval "require $plugin" unless $INC{$file}; # unless already loaded
    }
    
    my $CFG = $config->profile;
       $CFG->{PLUGINS}->{$_} = 1 for @plugins;
    
    return [@plugins];
}

sub mxn { goto &mixin }
sub mixin {
    my ($meta, $name, $data) = @_;
    my $config = find_or_create_cfg_attribute($meta);
    
    confess("config attribute not present") unless blessed($config);

    return undef unless ($name && $data);
    
    my $CFG = $config->profile;
       $CFG->{MIXINS}->{$name} = $data;
    
    return 'mixin', $name, $data;
}

sub pro { goto &profile }
sub profile {
    my ($meta, $name, $data) = @_;
    my $config = find_or_create_cfg_attribute($meta);
    
    confess("config attribute not present") unless blessed($config);

    return undef unless ($name && "CODE" eq ref $data);
    
    my $CFG = $config->profile;
       $CFG->{PROFILES}->{$name} = $data;
    
    return 'profile', $name, $data;
}

sub find_or_create_cfg_attribute {
    my $meta   = shift;
    my $config = $meta->find_attribute_by_name('config');
    
    unless ($config) {
        $config = $meta->add_attribute(
            'config',
            'is'    => 'rw',
            'isa'   => 'HashRef',
            'traits'=> ['Profile']
        );
        
        $config->{default} = sub {
            
            # not recommended (but i know not what i do)
            return $config->profile
        }
    }
    
    return $config;
}

no Moose::Exporter;

1;