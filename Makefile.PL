
use strict;
use warnings;

use 5.010;

use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Powerful Data Validation Framework",
  "AUTHOR" => "Al Newkirk <anewkirk\@ana.io>",
  "BUILD_REQUIRES" => {},
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Validation-Class",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Validation::Class",
  "PREREQ_PM" => {
    "Class::Forward" => 0,
    "Hash::Flatten" => 0,
    "Hash::Merge" => 0,
    "List::MoreUtils" => 0,
    "Module::Find" => 0,
    "Module::Runtime" => 0,
    "Scalar::Util" => 0
  },
  "TEST_REQUIRES" => {},
  "VERSION" => "7.900054",
  "test" => {
    "TESTS" => "t/*.t t/legacy/*.t t/legacy/regression/*.t t/legacy/regression/filters/*.t t/legacy/regression/validators/*.t"
  }
);


my %FallbackPrereqs = (
  "Class::Forward" => 0,
  "Hash::Flatten" => 0,
  "Hash::Merge" => 0,
  "List::MoreUtils" => 0,
  "Module::Find" => 0,
  "Module::Runtime" => 0,
  "Scalar::Util" => 0
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.63_03) } ) {
  delete $WriteMakefileArgs{TEST_REQUIRES};
  delete $WriteMakefileArgs{BUILD_REQUIRES};
  $WriteMakefileArgs{PREREQ_PM} = \%FallbackPrereqs;
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



