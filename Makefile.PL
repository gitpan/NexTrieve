require 5.000;
use ExtUtils::MakeMaker;
WriteMakefile (
 NAME		=> "NexTrieve",
 ($[ >= 5.005) ?
 (AUTHOR	=> 'Elizabeth Mattijsen (liz@dijkmat.nl)',
  ABSTRACT	=> 'Comprehensive Perl support for NexTrieve Search Engine') : (),
 VERSION_FROM	=> 'lib/NexTrieve.pm',
 PREREQ_PM	=> {'IO::Socket' => 0},
 EXE_FILES	=> [<script/*>],
);
