package NexTrieve::Index;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Index::ISA = qw(NexTrieve);
$NexTrieve::Index::VERSION = '0.01';

# Use other NexTrieve modules that we need always

use NexTrieve::Resource ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 filename or XML or NexTrieve::Resource object
#      3 reference to hash with method/value pairs (optional)
#      4..N filename of <ntv:docseq> containers to be indexed
# OUT: 1 instantiated NexTrieve::Index object

sub _new {

# Obtain the class of the object
# Attempt to create the base object
# Handle the resource specification if there is any
# Set any parameters if any specified
# Index any files if they are specified

  my $class = shift;
  my $self = $class->SUPER::_new( shift );
  $self->Resource( shift ) if @_;
  $self->Set( shift ) if ref($_[0]) eq 'HASH';
  $self->index( @_ ) if @_;

# Return the object

  return $self;
} #_new

#------------------------------------------------------------------------

# OUT: 1 flag whether associated NexTrieve executable installed and executable

sub executable { -x NexTrieve->new->NexTrievePath.'/ntvindex' } #executable

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 filename to store streamed XML in for reference
# OUT: 1 instantiated NexTrieve::Docseq object for streaming

sub Docseq { $_[0]->NexTrieve->Docseq->stream( shift->stream,@_ ) } #Docseq

#------------------------------------------------------------------------

# The following methods are for changing the object

#------------------------------------------------------------------------

#  IN: 1..N files to be indexed
# OUT: 1 exit status of external command (0 = success)

sub index {

# Obtain the object
# Obtain the command and log file
# Return now if there was an error

  my $self = shift;
  my ($command,$log) = $self->_setup;
  return unless $command;

# Obtain the list of files
# Create and save final filename
# Perform the indexing and obtain the exit status
# Add error if there was an invalid exit status
# Return exit status

  my $files = join( ' ',@_ );
  $self->{ref($self).'::command'} = $command =
   "$command -L $log $files 2>/dev/null";
  my $exit = system( $command );
  $self->_add_error( "Exit status from '$command': $exit" ) if $exit;
  return $exit;
} #index

#------------------------------------------------------------------------

#  IN: 1 flag indicating whether or not verbose result
# OUT: 1 handle to which you can print to index

sub stream {

# Obtain the object
# Obtain the command and log file
# Return now if there was an error

  my $self = shift;
  my ($command,$log) = $self->_setup( @_ );
  return unless $command;

# Save the command to be executed
# If we open the pipe to the indexer successfully
#  Return the handle to the pipe

  $self->{ref($self).'::command'}= $command= "|$command -L $log - 2>/dev/null";
  if (my $handle = $self->openfile( $command )) {
    return $handle;
  }

# Add error to the object and return

  $self->_add_error( "Cannot open pipe to indexer: $!" );
  return;
} #stream

#------------------------------------------------------------------------

# The following methods are for internal use only

#------------------------------------------------------------------------

#  IN: 1 verbose flag
# OUT: 1 command to execute (none: error)
#      2 logfile to save result to
# sets indexdir and log if not set already
# write resource file if not already written

sub _setup { shift->_command_log( 'ntvindex',@_ ) } #_setup

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Index - handle indexing with NexTrieve

=head1 SYNOPSIS

 use NexTrieve;
 die unless NexTrieve::Index->executable;

 $ntv = NexTrieve->new( | {method => value} );

 # using collections
 $collection = $ntv->Collection( path );
 $index = $collection->Index( mnemonic, | {method => value} );

 # using direct access
 $resource = $ntv->Resource( | file | xml | {method => value} );
 $index = $ntv->Index( | file | $resource | {method => value}, | {}, | files );

 # indexing created XML on the fly
 $docseq = $index->Docseq;
 $docseq->add( xml );
 $docseq->done;

 # indexing pre-created XML stored in files
 $index->index( file1,file2,file3 );

 # do it all yourself with created XML on the fly
 $handle = $index->stream;
 print $handle xml;
 close( $handle );

 $result = $index->result;

=head1 DESCRIPTION

The Index object of the Perl support for NexTrieve.  Do not create
directly, but through the Index method of the NexTrieve or the
NexTrieve::Collection object.

=head1 CLASS METHODS

These methods are available as class methods.

=head2 executable

 $executable = NexTrieve::Index->executable;

=head1 METHODS

These methods are available to the NexTrieve::Index object.

=head2 Docseq

 $docseq = $index->Docseq;

=head2 Resource

 $resource = $index->Resource( | file | xml | {method => value} );

=head2 index

 $index->index( file1,file2,file3 );

=head2 indexdir

 $index->indexdir( directory );
 $directory = $index->indexdir;

=head2 log

 $index->log( filename );
 $log = $index->log;

=head2 stream

 $handle = $index->stream;

=head2 result

 $handle = $index->result;

=head1 AUTHOR

Elizabeth Mattijsen, <liz@nextrieve.com>.

Please report bugs to <perlbugs@nextrieve.com>.

=head1 COPYRIGHT

Copyright (c) 1995-2002 Elizabeth Mattijsen <liz@nextrieve.com>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.nextrieve.com, the NexTrieve.pm and the other NexTrieve::xxx modules.

=cut
