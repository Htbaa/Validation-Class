# ABSTRACT: Generic Container Class for a Hash Reference

package Validation::Class::Mapping;

use strict;
use warnings;

use Validation::Class::Util '!has', '!hold';
use Hash::Merge ();

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Mapping;

    my $foos = Validation::Class::Mapping->new;

    $foos->add(foo => 'one foo');
    $foos->add(bar => 'one bar');

    print $foos->count; # 2 objects

=head1 DESCRIPTION

Validation::Class::Mapping is a container class that provides general-purpose
functionality for hashref objects.

=cut

=method new

    my $self = Validation::Class::Mapping->new;

=cut

sub new {

    my $class = shift;

    $class = ref $class if ref $class;

    my $arguments = $class->build_args(@_);

    my $self = bless {}, $class;

    $self->add($arguments);

    return $self;

}

=method add

    $self = $self->add(foo => 1, bar => 2);

=cut

sub add {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    while (my ($key, $value) = each %{$arguments}) {

        $self->{$key} = $value;

    }

    return $self;

}

=method clear

    $self = $self->clear;

=cut

sub clear {

    my ($self) = @_;

    $self->delete($_) for keys %{$self};

    return $self;

}

=method count

    my $count = $self->count;

=cut

sub count {

    my ($self) = @_;

    return scalar($self->keys);

}

=method delete

    $value = $self->delete($name);

=cut

sub delete {

    my ($self, $name) = @_;

    return delete $self->{$name};

}

=method defined

    $true if $self->defined($name) # defined

=cut

sub defined {

    my ($self, $index) = @_;

    return defined $self->{$index};

}

=method each

    $self = $self->each(sub{

        my ($key, $value) = @_;

    });

=cut

sub each {

    my ($self, $code) = @_;

    $code ||= sub {};

    while (my @args = each(%{$self})) {

        $code->(@args);

    }

    return $self;

}

=method exists

    $true if $self->exists($name) # exists

=cut

sub exists {

    my ($self, $name) = @_;

    return exists $self->{$name} ? 1 : 0;

}

=method get

    my $value = $self->get($name); # i.e. $self->{$name}

=cut

sub get {

    my ($self, $name) = @_;

    return $self->{$name};

}

=method grep

    $new_list = $self->grep(qr/update_/);

=cut

sub grep {

    my ($self, $pattern) = @_;

    $pattern = qr/$pattern/ unless "REGEXP" eq uc ref $pattern;

    return $self->new(map {$_=>$self->get($_)}grep{$_=~$pattern}($self->keys));

}

=method has

    $true if $self->has($name) # defined or exists

=cut

sub has {

    my ($self, $name) = @_;

    return ($self->defined($name) || $self->exists($name)) ? 1 : 0;

}

=method hash

    my $hash = $self->hash;

=cut

sub hash {

    my ($self) = @_;

    return {$self->list};

}

=method iterator

    my $next = $self->iterator();

    # defaults to iterating by keys but accepts: sort, rsort, nsort, or rnsort
    # e.g. $self->iterator('sort', sub{ (shift) cmp (shift) });

    while (my $item = $next->()) {
        # do something with $item (value)
    }

=cut

sub iterator {

    my ($self, $function, @arguments) = @_;

    $function = 'keys'
        unless grep { $function eq $_ } ('sort', 'rsort', 'nsort', 'rnsort');

    my @keys = ($self->$function(@arguments));

    my $i = 0;

    return sub {

        return unless defined $keys[$i];

        return $self->get($keys[$i++]);

    }

}

=method keys

    my @keys = $self->keys;

=cut

sub keys {

    my ($self) = @_;

    return (keys(%{$self->hash}));

}

=method list

    my %hash = $self->list;

=cut

sub list {

    my ($self) = @_;

    return (%{$self});

}

=method merge

    $self->merge($hashref);

=cut

sub merge {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    my $merger = Hash::Merge->new('LEFT_PRECEDENT');

    $self->add($merger->merge($arguments, $self->hash));

    return $self;

}

=method nsort

    my @keys = $self->nsort;

=cut

sub nsort {

    my ($self) = @_;

    my $code = sub { $_[0] <=> $_[1] };

    return $self->sort($code);

}

=method pairs

    my @pairs = $self->pairs;
    # or filter using $self->pairs('grep', $regexp);

    foreach my $pair (@pairs) {
        # $pair->{key} is $pair->{value};
    }

=cut

sub pairs {

    my ($self, $function, @arguments) = @_;

    $function ||= 'keys';

    my @keys = ($self->$function(@arguments));

    my @pairs = map {{ key => $_, value => $self->get($_) }} (@keys);

    return (@pairs);

}

=method rmerge

    $self->rmerge($hashref);

=cut

sub rmerge {

    my $self = shift;

    my $arguments = $self->build_args(@_);

    my $merger = Hash::Merge->new('RIGHT_PRECEDENT');

    $self->add($merger->merge($arguments, $self->hash));

    return $self;

}

=method rnsort

    my @keys = $self->rnsort;

=cut

sub rnsort {

    my ($self) = @_;

    my $code = sub { $_[1] <=> $_[0] };

    return $self->sort($code);

}

=method rsort

    my @keys = $self->rsort;

=cut

sub rsort {

    my ($self) = @_;

    my $code = sub { $_[1] cmp $_[0] };

    return $self->sort($code);

}

=method sort

    my @keys = $self->sort(sub{...});

=cut

sub sort {

    my ($self, $code) = @_;

    return "CODE" eq ref $code ?
        sort { $a->$code($b) } ($self->keys) : sort { $a cmp $b } ($self->keys);

}

=method values

    my @values = $self->values;

=cut

sub values {

    my ($self) = @_;

    return (values(%{$self->hash}));

}

1;
