
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Low-Fat Full-Flavored Data Modeling and Validation Framework",
  "AUTHOR" => "Al Newkirk <awncorp\@cpan.org>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Validation-Class",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Validation::Class",
  "PREREQ_PM" => {
    "Array::Unique" => 0,
    "Carp" => 0,
    "Hash::Flatten" => 0,
    "Hash::Merge" => 0,
    "Module::Find" => 0
  },
  "VERSION" => "5.60",
  "test" => {
    "TESTS" => "t/previous/*.t t/previous/filters/*.t t/previous/validators/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



