requires "Class::Forward" => "0";
requires "Hash::Flatten" => "0";
requires "Hash::Merge" => "0";
requires "List::MoreUtils" => "0";
requires "Module::Find" => "0";
requires "Module::Runtime" => "0";

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "6.30";
};
