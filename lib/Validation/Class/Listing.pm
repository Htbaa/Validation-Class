# ABSTRACT: Generic Container Class for an Array Reference

package Validation::Class::Listing;

use strict;
use warnings;

use Validation::Class::Util '!has', '!hold';
use List::MoreUtils 'uniq';

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Listing;

    my $foos = Validation::Class::Listing->new;

    $foos->add('foo');
    $foos->add('bar', 'baz');

    print $foos->count; # 3 objects

=head1 DESCRIPTION

Validation::Class::Listing is a container class that provides general-purpose
functionality for arrayref objects.

=cut

=method new

    my $self = Validation::Class::Listing->new;

=cut

sub new {

    my $class = shift;

    $class = ref $class if ref $class;

    my $arguments = isa_arrayref($_[0]) ? $_[0] : [@_];

    my $self = bless [], $class;

    $self->add($arguments);

    return $self;

}

=method add

    $self = $self->add('foo', 'bar');

=cut

sub add {

    my $self = shift;

    my $arguments = isa_arrayref($_[0]) ? $_[0] : [@_];

    push @{$self}, @{$arguments};

    return $self;

}

=method clear

    $self = $self->clear;

=cut

sub clear {

    my ($self) = @_;

    foreach my $pair ($self->pairs) {
        $self->delete($pair->{index});
    }

    return $self->new;

}

=method count

    my $count = $self->count;

=cut

sub count {

    my ($self) = @_;

    return scalar($self->list);

}

=method delete

    $value = $self->delete($index);

=cut

sub delete {

    my ($self, $index) = @_;

    return delete $self->[$index];

}

=method defined

    $true if $self->defined($name) # defined

=cut

sub defined {

    my ($self, $index) = @_;

    return defined $self->[$index];

}

=method each

    $self = $self->each(sub{

        my ($index, $value) = @_;

    });

=cut

sub each {

    my ($self, $code) = @_;

    $code ||= sub {};

    my $i=0;

    foreach my $value ($self->list) {

        $code->($i, $value); $i++;

    }

    return $self;

}

=method first

    my $value = $self->first;

=cut

sub first {

    my ($self) = @_;

    return $self->[0];

}

=method get

    my $value = $self->get($index); # i.e. $self->[$index]

=cut

sub get {

    my ($self, $index) = @_;

    return $self->[$index];

}

=method grep

    $new_list = $self->grep(qr/update_/);

=cut

sub grep {

    my ($self, $pattern) = @_;

    $pattern = qr/$pattern/ unless "REGEXP" eq uc ref $pattern;

    return $self->new(grep { $_ =~ $pattern } ($self->list));

}

=method has

    $true if $self->has($name) # defined

=cut

sub has {

    my ($self, $index) = @_;

    return $self->defined($index) ? 1 : 0;

}

=method iterator

    my $next = $self->iterator();

    # defaults to iterating by keys but accepts sort, rsort, nsort, or rnsort
    # e.g. $self->iterator('sort', sub{ (shift) cmp (shift) });

    while (my $item = $next->()) {
        # do something with $item
    }

=cut

sub iterator {

    my ($self, $function, @arguments) = @_;

    $function = 'list'
        unless grep { $function eq $_ } ('sort', 'rsort', 'nsort', 'rnsort');

    my @keys = ($self->$function(@arguments));

    @keys = $keys[0]->list if $keys[0] eq ref $self;

    my $i = 0;

    return sub {

        return unless defined $keys[$i];

        return $keys[$i++];

    }

}

=method join

    my $string = $self->join($delimiter);

=cut

sub join {

    my ($self, $delimiter) = @_;

    return join($delimiter, ($self->list));

}

=method last

    my $value = $self->last;

=cut

sub last {

    my ($self) = @_;

    return $self->[-1];

}

=method list

    my @list = $self->list;

=cut

sub list {

    my ($self) = @_;

    return (@{$self});

}

=method nsort

    my @list = $self->nsort;

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
        # $pair->{index} is $pair->{value};
    }

=cut

sub pairs {

    my ($self, $function, @arguments) = @_;

    $function ||= 'list';

    my @values = ($self->$function(@arguments));

    return () unless @values;

    @values = $values[0]->list if ref $values[0] && ref $values[0] eq ref $self;

    my $i=0;

    my @pairs = map {{ index => $i++, value => $_ }} (@values);

    return (@pairs);

}

=method rnsort

    my @list = $self->rnsort;

=cut

sub rnsort {

    my ($self) = @_;

    my $code = sub { $_[1] <=> $_[0] };

    return $self->sort($code);

}

=method rsort

    my @list = $self->rsort;

=cut

sub rsort {

    my ($self) = @_;

    my $code = sub { $_[1] cmp $_[0] };

    return $self->sort($code);

}

=method sort

    my @list = $self->sort(sub{...});

=cut

sub sort {

    my ($self, $code) = @_;

    return "CODE" eq ref $code ?
        sort { $a->$code($b) } ($self->keys) : sort { $a cmp $b } ($self->list);

}

=method unique

    my @list = $self->unique();

=cut

sub unique {

    my ($self) = @_;

    return uniq ($self->list);

}

1;
