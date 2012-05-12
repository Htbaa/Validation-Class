BEGIN {
    
    use FindBin;
    use lib $FindBin::Bin . "/lib";
    
}

use Test::More;

SKIP: {
    
    eval { require 'DBI.pm' && require 'DBD/SQLite.pm' };
    
    plan skip_all => 'DBI or DBD::SQLite is not installed.' if $@;
    
    package TestClass::ObjectKeyword;
    
    use DBI;
    use Validation::Class;
    
    fld name => {
        required => 1,
    };
    
    obj _build_dbh => {
        type => 'DBI',
        init => 'connect',
        args => sub {
            
            my ($self) = @_;
            
            return (
                join(':', 'dbi', 'SQLite', "dbname=". $self->name),
                "",
                ""
            )
            
        }
    };
    
    has dbh => sub { shift->_build_dbh };
    
    sub connect {
    
        my ($self) = @_;
        
        if ($self->validate('name')) {
        
            if ($self->dbh) {
                
                my $db = $self->dbh;
                
                # ... do something else with DBI
                
                return 1;
                
            }
            
            $self->set_errors($DBI::errstr);
        
        }
        
        return 0;
    
    }
    
    package main;
    
    my $class = "TestClass::ObjectKeyword";
    my $self  = $class->new;
    
    ok $class eq ref $self, "$class instantiated";
    
    ok ! $self->connect, "class did not connect() as expected";
    
    $self->name(':memory:');
    
    ok $self->connect, "class DID connect() successfully as expected";
    
    ok 'DBI::db' eq ref $self->dbh, "class has an instantiated DBI object";
    
    ok 'DBI::db' eq ref $self->_build_dbh, "class can build a new DBI object";
    
    # ...
    
}

done_testing;