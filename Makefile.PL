require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile (
 NAME		=> "NexTrieve",
 ($[ >= 5.005) ?
 (AUTHOR	=> 'Elizabeth Mattijsen (liz@nextrieve.com)',
  ABSTRACT	=> 'Perl support for NexTrieve Search Engine') : (),
 VERSION_FROM	=> 'lib/NexTrieve.pm',
 PREREQ_PM	=> {'IO::Socket' => 0},
);
