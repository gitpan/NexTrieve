package NexTrieve::Index;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Index::ISA = qw(NexTrieve);
$NexTrieve::Index::VERSION = '0.33';

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
  $self->Resource( ref($_[0]) eq 'ARRAY' ? @{shift(@_)} : shift ) if @_;
  $self->Set( shift ) if ref($_[0]) eq 'HASH';
  $self->index( @_ ) if @_;

# Return the object

  return $self;
} #_new

#------------------------------------------------------------------------

#  IN: 1 which executable (default: 'ntvindex')
# OUT: 1 flag: whether it should work or not
#      2 expiration date of license ('' if not known)
#      3 software version
#      4 database version
#      5 whether threaded or no

sub executable { NexTrieve->executable( $_[1] || 'ntvindex' ) } #executable

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1..N filename(s) to store streamed XML in for reference
# OUT: 1 instantiated NexTrieve::Docseq object for streaming

sub Docseq { $_[0]->NexTrieve->Docseq->stream( shift->stream,@_ ) } #Docseq

#------------------------------------------------------------------------

# OUT: 1 instantiated NexTrieve::Resource object

sub ResourceFromIndex {

# Obtain the object
# Obtain the program name
# Remove the superfluous -I and replace by --xml
# Obtain the indexdir

  my $self = shift;
  my $command = $self->executable( 'ntvcheck' );
  my $indexdir = $self->indexdir || $self->Resource->indexdir || '';

# If we don't have an indexdir yet
#  Add error and return

  unless ($indexdir) {
    $self->_add_error( "Must have an indexdir" );
    return;
  }

# Create the completed command
# Set the last command executed
# Obtain the XML
# Reset xml if no indexcreation section (older NexTrieve's output garbage then)

  $command .= " --xml $indexdir";
  $self->{ref($self).'::command'} = $command;
  my $xml = $self->slurp( $self->openfile( "$command|" ) );
  $xml = '' unless $xml =~ m#<indexcreation>.*?</indexcreation>#s;

# Create a new Resource object
# Read the complete XML if there is any

  my $resource = $self->NexTrieve->Resource;
  $resource->read_string( <<EOD ) if $xml;
<?xml version="1.0" encoding="utf-8"?>
<ntv:resource>
<indexdir name="$indexdir">
$xml</ntv:resource>
EOD

# Add error if there is no XML (open failed or nothing returned)
# Return the resource document

  $resource->_add_error( "Could not read <indexcreation> information" )
   unless $xml;
  return $resource;
} #ResourceFromIndex

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
  $self->{ref($self).'::command'} = $command = "$command -L $log $files";
  my $exit = system( $command );
  $self->_add_error( "Exit status from '$command': $exit" ) if $exit;
  return $exit;
} #index

#------------------------------------------------------------------------

#  IN: 1 mask to be applied to mkdir
# OUT: 1 result of mkdir

sub mkdir {

# Obtain the object
# Obtain the indexdir

  my $self = shift;
  my $indexdir = $self->indexdir || $self->Resource->indexdir || '';

# Return the result of the creation of the directory if there is one known
# Add error and return

  return CORE::mkdir( $indexdir,shift || 0777 ) if $indexdir;
  $self->_add_error( "Don't know which indexdir to create" );
  return 0;
} #mkdir

#------------------------------------------------------------------------

#  IN: 1 reference to hash with keyed parameters
# OUT: 1 0 if success, else exit code

sub optimize {

# Obtain the object
# Obtain the reference to the hash with parameters
# Create the initial command
# Get rid of the -I and obtain the indexdir

  my $self = shift;
  my $hash = shift || {};
  my $command = $self->_command_log( 'ntvopt' );
  my $indexdir = $command =~ s# -I (\S+)# $1# ? $1 : '';

# If we don't have an indexdir
#  Add error and return

  unless ($indexdir) {
    $self->_add_error( "Must know what index to optimize" );
    return;
  }

# For all of the parameters that can be specified
#  Reloop if there is no parameter specified
#  Add the parameter to the command line

  foreach my $parameter (qw(tempdir nwaymerge opt)) {
    next unless $hash->{$parameter};
    $command .= " --$parameter=$hash->{$parameter}";
  }

# Set the field name
# Save the command to be executed
# Do the optimization, if failed
#  Add error and return

  my $field = ref($self).'::command';
  $self->{$field} = $command;
  if (my $exit = system( $command )) {
    $self->_add_error( "ntvopt exited with code $exit" );
    return $exit;
  }

# Create the command and save in the object
# Start using the optimized files, if failed
#  Add error
  
  my $ntvpath = $self->NexTrievePath;
  $self->{$field} = $command = "$ntvpath/ntvidx-useopt.sh $indexdir";
  if (my $exit = system( $command )) {
    $self->_add_error( "ntvidx-useopt.sh exited with code $exit" );
    return $exit;
  }
  return 0;
} #optimize

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

  $self->{ref($self).'::command'}= $command= "|$command -L $log -";
  if (my $handle = $self->openfile( $command )) {
    return $handle;
  }

# Add error to the object and return

  $self->_add_error( "Cannot open pipe to indexer: $!" );
  return;
} #stream

#------------------------------------------------------------------------

sub update_end {

# Obtain the object
# Obtain the class
# Obtain the base index directory
# Obtain the new indexdir (as stored in the "indexdir")

  my $self = shift;
  my $class = ref($self);
  my $indexdir = $self->{$class.'::baseindexdir'};
  my $indexdirnew = $self->indexdir;

# If the current indexdir is different from what we expect
#  Add error and return
  
  if ($indexdirnew ne "$indexdir.new") {
    $self->_add_error( "Strange things in no man's land" );
    return;
  }

# Set the old indexdirectry name
# If it exists
#  Remove all of the files in there
#  Remove the now supposedly empty directory
#  If it still exists
#   Add error and return

  my $indexdirold = "$indexdir.old";
  if (-d $indexdirold) {
    unlink( <$indexdirold/*> );
    rmdir( $indexdirold );
    if (-d $indexdirold) {
      $self->_add_error( "Could not remove directory '$indexdirold'" );
      return;
    }
  }

# Delete the base indexdir field
# If there was a previous "local" indexdir value
#  Restore that
# Else
#  Remove the "local" indexdir value
# Delete the old indexdir field
  
  delete( $self->{$class.'::baseindexdir'} );
  if (my $oldindexdir = $self->{$class.'::oldindexdir'} || '') {
    $self->indexdir( $oldindexdir );
  } else {
    delete( $self->{$class.'::indexdir'} );
  }
  delete( $self->{$class.'::oldindexdir'} );

# Swap out the current index to the old one
# Swap in the new one to the current one

  rename( $indexdir,$indexdirold );
  rename( $indexdirnew,$indexdir );
} #update_end

#------------------------------------------------------------------------

#  IN: 1 whether incremental (default: 0 = full)

sub update_start {

# Obtain the object
# Obtain the current indexdir of the index object itself
# Obtain the indexdir that we're gonna use
# If we don't have an indexdir
#  Add error and return

  my $self = shift;
  my $oldindexdir = $self->indexdir;
  my $indexdir = $oldindexdir || $self->Resource->indexdir;
  unless ($indexdir) {
    $self->_add_error( "Must have an indexdir specification" );
    return;
  }

# Create the new directory name
# If it exists already
#  Make sure it is clean indexing wise
# Else (doesn't exist yet)
#  Create the new directory
#  If it still doesn't exist
#   Add error and return

  my $indexdirnew = "$indexdir.new";
  if (-d $indexdirnew) {
    unlink( <$indexdirnew/*.ntv> );
  } else {
    CORE::mkdir( $indexdirnew,0777 ); # we have a subroutine by the same name
    unless (-d $indexdirnew) {
      $self->_add_error( "Cannot create directory '$indexdirnew': $!" );
      return;
    }
  }

# If we're supposed to do an incremental update
#  If there is a current directory
#   Obtain the copy of currently existing files
#   If copy to the new directory failed
#    Add error and return

  if (shift || '') {
    if (-d $indexdir) {
      my @file = <$indexdir/*.ntv>;
      if (my $exit = system( "cp -p @file $indexdirnew" )) {
        $self->_add_error( "Error in copying file(s) @file: $exit" );
        return;
      }
    }
  }

# Obtain the class of the object
# Save the base indexdir setting
# Save the old indexdir setting of the object itself
# Set the indexdir that should be used for the actual indexing

  my $class = ref($self);
  $self->{$class.'::baseindexdir'} = $indexdir;
  $self->{$class.'::oldindexdir'} = $oldindexdir;
  $self->indexdir( $indexdirnew );
} #update_start

#------------------------------------------------------------------------

# The following methods are for internal use only

#------------------------------------------------------------------------

#  IN: 1 verbose flag
# OUT: 1 command to execute (none: error)
#      2 logfile to save result to
# sets indexdir and log if not set already
# write resource file if not already written ?

sub _setup { shift->_command_log( 'ntvindex',@_ ) } #_setup

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Index - handle indexing with NexTrieve

=head1 SYNOPSIS

 use NexTrieve;
 die unless NexTrieve::Index->executable;

 $ntv = NexTrieve->new( | {method => value} );

 # using direct access
 $resource = $ntv->Resource( | file | xml | {method => value} );
 $index = $ntv->Index( | file | $resource | {method => value}, | {}, | @files );

 # use version control (new -> current -> old)
 $index->update_start( | incremental );

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

 # finish version control (new -> current -> old)
 $index->update_end;
 $ntv->Daemon( $resource )->restart;

=head1 DESCRIPTION

The Index object of the Perl support for NexTrieve.  Do not create
directly, but through the Index method of the NexTrieve object.

=head1 CREATING AN INDEX

The process of creating a NexTrieve index is straightforward: create a
directory which is to contain the result of the indexing process (also
referred to as the L<indexdir>).  Create a NexTrieve::Index object with
its L<Resource>s pointing to the right directory and perform your indexing
by either calling method L<index> or through creating a magic L<Docseq>
object that is used by any of the other NexTrieve::xxx modules.

=head1 UPDATING AN INDEX

Updating an already existing index can be done in two ways: either
incrementally (only adding documents in a document sequence that were new or
changed) or by doing a full re-index.

If you are running a search service on an already existing index, you do not
want that search service to be interrupted by the indexing process.  To be
able to create a new index while not interrupting the running search service,
the following procedure is performed:

=over 2

=item 1. create a directory with same name as the indexdir with extension .new

As a first step, a directory is created with the same name as the original
indexdirectory, but with the extension ".new".  If such a directory already
exists, it is cleared of any files that exist in it.

=item 2. copy current index into the new indexdirectory if incremental update

If an incremental update was requested, all the files necessary for that index
are copied to the new directory.

=item 3. temporarily override the indexdir setting

To index using this new indexdirectory, a temporary override of the L<indexdir>
is necessary.

-item 4. perform the indexing

Do the indexing that needs to be done, either re-indexing all documents or
just the documents that were new or changed, depending on whether you preferred
an incremental indexing or not.

=item 5. swap indexdirectories and restore indexdir setting

Once the indexing is done, we now have two indexdirectories: the live one and
the one with the ".new" extension.  The live one is renamed to the same name,
but with the ".old" extension.  The ".new" extension is removed from the new
indexdirectory.  No other action is needed to be taken if you use the
on-demand way of searching, using the "ntvsearch" program.

=item 6. restart server process

If there is a NexTrieve server process running using the original
indexdirectory, it should be stopped and started again using the new
indexdirectory (that now has the same name as the original indexdirectory).

=back

Steps 1, 2 and 3 of this procedure are performed by the L<update_start> method.
Step 4 can be done in many ways, e.g. using the L<files> method or having
other modules use the magic L<Docseq> method.  Step 5 is performed by the
L<update_end> method.  Step 6 can be performed by the "restart" method of
the NexTrieve::Daemon module.

=head1 CLASS METHODS

These methods are available as class methods.

=head2 executable

 $executable = NexTrieve::Index->executable;
 ($program,$expiration,$software,$database) = NexTrieve::Index->executable;

Return information about the associated NexTrieve program "ntvindex".

The first output parameter contains the full program name of the NexTrieve
executable "ntvindex".  It contains the empty string if the "ntvindex"
executable could not be found or is not executable by the effective user.
Can be used as a flag.  Is the only parameter returned in a scalar context.

If this method is called in a list context, an attempt is made to execute
the NexTrieve program "ntvindex" to obtain additional information.  Then
the following output parameters are returned.

The second output parameter returns the expiration date of the license that
NexTrieve is using by default.  If available, then the date is returned as a
datestamp (YYYYMMDD).

The third output parameter returns the version of the NexTrieve software that
is being used.  It is a string in the form "M.m.rr", whereby "M" is the major
release number, "m" is the minor release number and "rr" is the build number.

The fourth output parameter returns the version of the internal database that
will be created by the version of the NexTrieve software that is being used.
It is a string in the form "M.m.rr", whereby "M" is the major release number,
"m" is the minor release number and "rr" is the build number.

=head1 OBJECT METHODS

These methods return objects.

=head2 Docseq

 $docseq = $index->Docseq( | extrafile | extrahandle );

The "Docseq" method returns a special purpose streaming NexTrieve::Docseq
that will cause any data to be added to the NexTrieve::Docseq object to be
immediately indexed.

Each input parameter specified indicates either:

 - a filename to store a copy of the XML indexed
 - a handle to write a copy of the XML to

This allows you the benefit of immediately indexing anything that is generated
but still keep a copy of the XML generated available for reference.

See the NexTrieve::Docseq module for more information.

=head2 Resource

 $resource = $index->Resource;
 $index->Resource( $resource | file | xml | {method => value} );

The "Resource" method is primarily intended to allow you to obtain the
NexTrieve::Resource object that is (indirectly) created when the
NexTrieve::Index object is created.  If necessary, it can also be used
to create a new NexTrieve::Resource object associated with the
NexTrieve::Index object.

See the NexTrieve::Resource module for more information.

=head2 ResourceFromIndex

 $resource = $index->ResourceFromIndex;

If for whatever reason the resource-file of an already existing NexTrieve index
is lost, then the "ResourceFromIndex" method can be used to create the basic
NexTrieve::Resource object that corresponds to that index.

=head1 OTHER METHODS

The following methods set and return other aspects of the NexTrieve::Index
object.

=head2 index

 $error = $index->index( file1,file2,file3 );

The "index" method allows for a quick and dirty index of document sequences
that have been created previously and saved in files.  The input parameters
specify the names of the files that should be indexed.

The output parameter returns the exit process value of the "ntvindex" program.
Success is indicated by the value 0, any other value indicates an error in
the indexing process in which case an error is raised.  Any specific error
messages from the "ntvindex" program can be obtained through the L<result>
method.

=head2 indexdir

 $index->indexdir( directory );
 $directory = $index->indexdir;

The "indexdir" method specifies an indexdirectory B<other> than the
indexdirectory that is specified in the L<Resource> object.  By default, the
indexdirectory information from the L<Resource> object is used.

=head2 log

 $index->log( filename );
 $log = $index->log;

The "log" method specifies the name of the file in which any error and other
messages are stored during the indexing process performed by the "ntvindex"
program.  If no filename is specified before the indexing process commences,
the file "ntvindex.log" located in the L<indexdir> will be assumed.

Use method L<result> to read from the logfile.

=head2 optimize

 $error = $index->optimize;

The "optimize" method performs the optimization of an index created by the
"ntvindex" program.  To be able to do this, the "ntvopt" program must be
installed with a valid license.

The output parameter returns the exit process value of the "ntvopt" program.
Success is indicated by the value 0, any other value indicates an error in
the optimization process in which case an error is raised.

=head2 result

 $text = $index->result;

Each consecutive call to the "result" method returns any lines that were added
to the L<log>file since the last call to the "result" method.  It can be used
in a threaded environment to monitor the progress of the indexing process.  Or 
it can be used to view the final result after the indexing process is done.

=head2 stream

 $handle = $index->stream;
 print $handle "<ntv:docseq>....</ntv:docseq>";

The "stream" method returns a special purpose handle to which a document
sequence can be written that you want to be indexed immediately.  It is
rarely needed directly.  Internally, it is used to give the L<Docseq> method
its magic.

=head2 update_end

 $index->update_end;

The "update_end" method performs step 5 of the L<UPDATING AN INDEX> process.

=head2 update_start

 $index->update_start( | incremental );

The "update_start" method performs steps 1, 2 and 3 of the L<UPDATING AN INDEX>
process.  This input parameter specifies whether the indexing process to be
performed should be incremental or not.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 1995-2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.nextrieve.com, the NexTrieve.pm and the other NexTrieve::xxx modules.

=cut
