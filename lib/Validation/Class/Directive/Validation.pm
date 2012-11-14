# ABSTRACT: Validation Directive for Validation Class Field Definitions

package Validation::Class::Directive::Validation;

use base 'Validation::Class::Directive';

use Validation::Class::Core;

# VERSION

=head1 SYNOPSIS

    use Validation::Class::Directive::Validation;

    my $directive = Validation::Class::Directive::Validation->new;

=head1 DESCRIPTION

Validation::Class::Directive::Validation is a core validation class field directive
that provides the ability to do some really cool stuff only we haven't
documented it just yet.

=cut

has 'mixin'   => 0;
has 'field'   => 1;
has 'multi'   => 0;
has 'message' => '%s could not be validated';

sub after_validation {

    my ($self, $proto, $field, $param) = @_;

    $self->after_validation_delete_clones($proto, $field, $param);

    return $self;

}

sub after_validation_delete_clones {

    my ($self, $proto, $field, $param) = @_;

    my $name = $field->name;

    my ($key, $index) = $name =~ /(.*)\:(\d+)$/;

    if ($key && defined $index) {

        my $value = $self->params->delete($name);

        $self->params->{$key} ||= [];

        $self->params->{$key}->[$index] = $value;

    }

    return $self;

}

sub before_validation {

    my ($self, $proto, $field, $param) = @_;

    $self->before_validation_create_clones($proto, $field, $param);

    return $self;

}

sub before_validation_create_clones {

    my ($self, $proto, $field, $param) = @_;

    # clone fields to handle parameters with multi-values

    if (isa_arrayref($param)) {

        # clone deterministically

        my $name = $field->name;

        for (my $i=0; $i < @{$param}; $i++) {

            my $clone = "$name:$i";

            $self->params->add($clone => $param->[$i]);

            my $label = ($field->label || $name);

            $self->clone($name => $clone, { label  => "$label #" . ($i+1) });

            # add clones to field list to be validated
            push @{$self->stash->{'validation.fields'}}, $clone
                if grep { $_ eq $name } @{$self->stash->{'validation.fields'}}
            ;

            # record clones (to be reaped later)
            push @{$self->stash->{'directive.validation.clones'}}, $clone;

        }

        $self->params->delete($name);

        # remove the field the clones are based on from the fields list
        @{$self->stash->{'validation.fields'}} =
            grep { $_ ne $name } @{$self->stash->{'validation.fields'}}
            if @{$self->stash->{'validation.fields'}}
        ;

    }

    return $self;

}

sub validate {

    my ($self, $proto, $field, $param) = @_;

    if (defined $field->{validation}) {

        my $context = $proto->stash->{'validation.context'};

        my $count  = ($proto->errors->count+$field->errors->count);
        my $failed = !$field->validation->($context,$field,$proto->params)?1:0;
        my $errors = ($proto->errors->count+$field->errors->count)>$count ?1:0;

        # error handling; did the validation routine pass or fail?

        # validation passed with no errors
        if (!$failed && !$errors) {
            # noop
        }

        # validation failed with no errors
        elsif ($failed && !$errors) {
            # use custom or default errors
            if ($field->error) {
                $field->errors->add($field->error);
            }
            else {
                $field->errors->add(
                    $self->error($field->label||$field->name)
                );
            }
        }

        # validation passed with errors
        elsif (!$failed && $errors) {
            # noop -- but acknowledge errors have been set
        }

        # validation failed with errors
        elsif ($failed && $errors) {
            # assume errors have been set from inside the validation routine
        }

    }

    return $self;

}

1;
