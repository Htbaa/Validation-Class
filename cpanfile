# This file is generated by Dist::Zilla::Plugin::CPANFile v6.030
# Do not edit this file directly. To change prereqs, edit the `dist.ini` file.

requires "Clone" => "0";
requires "Hash::Flatten" => "0";
requires "Hash::Merge" => "0";
requires "List::MoreUtils" => "0";
requires "Module::Find" => "0";
requires "Module::Runtime" => "0";
requires "Scalar::Util" => "0";
requires "perl" => "5.010";

on 'test' => sub {
  requires "perl" => "5.010";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};
