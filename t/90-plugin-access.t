BEGIN {
    
    use FindBin;
    use lib $FindBin::Bin . "/myapp/lib";
    
}

use Test::More;

SKIP: {
    
    eval { require 'Validation/Class/Plugin/FormFields.pm' };
    
    $@ ?
        plan skip_all => 'Validation::Class::Plugin::FormFields is not installed.' :
        eval <<'CLASS';
package TestClass::WithPlugins::Plugin::Test001;

use Validation::Class 'has';

has one => 1;

package TestClass::WithPlugins;

use Validation::Class;
set plugins => [
    'FormFields',
    '+TestClass::WithPlugins::Plugin::Test001'
];

fld name => {
    required => 1
};

1;
CLASS

    package main;
    
    my $class = "TestClass::WithPlugins";
    my $self  = $class->new;
    
    ok $class eq ref $self, "$class instantiated";
    
    my $forms = $self->plugin('form_fields');
    
    ok $forms, 'plugin method returned a true value for form_fields';
    
    my $test1 = $self->plugin('plugin:test001');
    
    ok $test1, 'plugin method returned a true value for form_fields';
    
}

done_testing;