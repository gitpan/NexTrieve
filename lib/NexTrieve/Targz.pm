package NexTrieve::Targz;

# Set modules to inherit from
# Set version information
# Make sure we do everything by the book from now on

@ISA = qw(NexTrieve);
$VERSION = '0.41';
use strict;

# Make sure we use the modules that we need here

use Cwd qw(cwd);
use File::Copy qw(copy);
use NexTrieve::RFC822 ();

# Initialize the new message delimiter
# Initialize the version of tar to be used

my $newmessagedelimiter = '^From ';
my $tar = $^O =~ m#^(?:darwin)$# ? 'gnutar' : 'tar';

# Satisfy -require-

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 directory to work on (assume current directory)
#      3 reference to parameter hash to be passed to object (optional)
# OUT: 1 instantiated NexTrieve::Targz object

sub _new {

# Create an object of the right class
# Obtain the class

  my $self = shift->SUPER::_new( shift );
  my $class = ref($self);

# Obtain the name of the work directory
# Make sure it's absolute
# Obtain the name of the directory to use
# Make sure it's absolute
# Remove trailing slash and optional dot if there is one

  my $work = $self->Tmp.'/Targz';
  $work = cwd."/$work" unless $work =~ s#^\s*(?=/)##;
  my $directory = shift || '';
  $directory = cwd."/$directory" unless $directory =~ s#^\s*(?=/)##;
  $directory =~ s#/\.?$##;

# For all of the (sub)directories that should exist
#  Reloop if it exists
#  Attempt to make it, return with error if failed

  foreach ($work,"$work/$$",$directory,"$directory/rfc","$directory/xml") {
    next if -d;
    return $self->_add_error( "Error in mkdir $_: $!" ) unless mkdir( $_,0777 );
  }

# Set the real work directory to work on
# Set the directory to work on
# Process any parameter hash if specified
# Return the object

  $self->{$class.'::work'} = "$work/$$";
  $self->{$class.'::directory'} = $directory;
  $self->Set( @_ ) if @_;
  return $self;
} #_new

#------------------------------------------------------------------------

#  IN: 1 existing Docseq object to use (optional: create new one if not exists)
#      2 reference to method/value pair hash
# OUT: 1 instantiated Docseq object

sub Docseq {

# Obtain the object
# Create the field name of the RFC822 object
# Obtain the RFC822 object (from parameter or field) or create a new one
# Set the parameters if any specified
# Return the object, setting field on the fly

  my $self = shift;
  my $field = ref($self).'::docseq';
  my $docseq = ref($_[0]) eq 'NexTrieve::Docseq' ?
   shift : $self->{$field} || $self->NexTrieve->Docseq;
  $docseq->Set( @_ ) if @_;
  return $self->{$field} = $docseq;
} #Docseq

#------------------------------------------------------------------------

#  IN: 1 reference to hash with any extra parameters
# OUT: 1 instantiated Resource object

sub Resource { shift->RFC822->Resource( @_ ) } #Resource

#------------------------------------------------------------------------

#  IN: 1 existing RFC822 object to use (optional: create new one if not exists)
#      2 reference to method/value pair hash
# OUT: 1 instantiated RFC822 object

sub RFC822 {

# Obtain the object
# Create the field name of the RFC822 object
# Obtain the RFC822 object (from parameter or field) or create a new one
# Set the parameters if any specified
# Return the object, setting field on the fly

  my $self = shift;
  my $field = ref($self).'::rfc822';
  my $rfc822 = ref($_[0]) eq 'NexTrieve::RFC822' ?
   shift : $self->{$field} || $self->NexTrieve->RFC822;
  $rfc822->Set( @_ ) if @_;
  return $self->{$field} = $rfc822;
} #RFC822

#------------------------------------------------------------------------

# Following methods change aspects of the object

#------------------------------------------------------------------------

#  IN: 1..N names of files or references to lists of files to be added
#           (default: all files with .new extension in directory)
# OUT: 1 number of files added

sub add_file {

# Obtain the object
# Obtain the class
# Obtain the RFC822 object if any
# Obtain the Docseq object if any

  my $self = shift;
  my $class = ref($self);
  my $rfc822 = $self->{$class.'::rfc822'} || '';
  my $docseq = $self->{$class.'::docseq'} || '';

# Initialize the ordinals hash
# Obtain the original directory
# Obtain the directory to work in

  my %ordinal;
  my $cwd = cwd;
  my $directory = $self->directory;

# If failed to move to right directory
#  Add error and return
# Obtain the base name of the tarfiles to work with

  unless (chdir( $directory )) {
    $self->_add_error( "Cannot chdir to $directory" );
    return 0;
  }
  (my $name = $directory) =~ s#^.*/##;

# Initialize the list of files to be unlinked upon success
# Obtain the remove original flag
# Initializ number of files handled

  my @unlink;
  my $rm_original = $self->rm_original;
  my $files = 0;

# Obtain the files to work on if none specified
# For all of the parameters specified
#  Create a reference to it if it is not a reference to a list, else use that
#  For all of the elements in the list reference
#   Obtain the absolute filename
#   Attempt to open the file
#   Reloop if failed

  @_ = <$directory/*.new> unless @_;
  foreach my $element (@_) {
    my $list = ref($element) eq 'ARRAY' ? $element : [$element];
    foreach (@{$list}) {
      my $filename = m#^/# ? $_ : "$cwd/$_";
      my $handle = $self->openfile( $filename );
      next unless $handle;

#   Save in the list of files to remove if so requested
#   Attempt to obtain a time value for this message
#   If we don't have a time
#    Add error message and reloop
#   Incement number of files handled
#   Handle all the stuff needed for this file, reloop if ok
#   Return now indicating error

      push( @unlink,$filename ) if $rm_original;
      my $time = _epoch( $handle );
      unless ($time) {
#        $self->_add_error( "Could not determine originating time of $_" );
        next;
      }
      $files++;
      next if _handle_file( $self,$directory,$name,$filename,$time,\%ordinal );
      return $files-1;
    }
  }

# Finish up the adding process
# Restore the original directory
# Remove the temp directory
# Remove files to be removed

  _finish_add( $self,$directory,$name,\%ordinal,$rfc822,$docseq );
  chdir( $cwd );
  unlink( @unlink ) if @unlink;
  return $files;
} #add_file

#------------------------------------------------------------------------

#  IN: 1..N names of mboxes or references to lists of mboxes to be added
# OUT: 1 whether successful

sub add_mbox {

# Obtain the object
# Obtain the class
# Obtain the RFC822 object if any
# Obtain the Docseq object if any

  my $self = shift;
  my $class = ref($self);
  my $rfc822 = $self->{$class.'::rfc822'} || '';
  my $docseq = $self->{$class.'::docseq'} || '';

# Initialize the ordinals hash
# Obtain the original directory
# Obtain the directory to work in

  my %ordinal;
  my $cwd = cwd;
  my $directory = $self->directory;

# If failed to move to right directory
#  Add error and return
# Obtain the base name of the tarfiles to work with

  unless (chdir( $directory )) {
    $self->_add_error( "Cannot chdir to $directory" );
    return;
  }
  (my $name = $directory) =~ s#^.*/##;

# Initialize the list of files to be unlinked upon success
# Obtain the remove original flag

  my @unlink;
  my $rm_original = $self->rm_original;

# For all of the parameters specified
#  Create a reference to it if it is not a reference to a list, else use that
#  For all of the elements in the list reference
#   Obtain the absolute filename
#   Attempt to open the file
#   Reloop if failed
#   Save in the list of files to remove if so requested

  foreach my $element (@_) {
    my $list = ref($element) eq 'ARRAY' ? $element : [$element];
    foreach (@{$list}) {
      my $mbox = m#^/# ? $_ : "$cwd/$_";
      my $mbox_handle = $self->openfile( $mbox );
      next unless $mbox_handle;
      push( @unlink,$mbox ) if $rm_original;

#   Initialize line number
#   Get the first line
#   While we're at a new message boundary
#    Initialize the message
#    Save the starting linenumber
#    While we're _not_ at a message boundary, fetching new line on the fly
#     Increment line number
#     Add line to message
#     Write this message to the archive if we're archiving

      my $linenumber = 0;
      my $line = <$mbox_handle>;
      while (defined($line) and $line =~ m#$newmessagedelimiter#o) {
        my $message = $line;
        my $start = $linenumber++;
        while (defined($line = <$mbox_handle>) and
               $line !~ m#$newmessagedelimiter#o) {
          $linenumber++;
          $message .= $line;
        }

#   Attempt to obtain a time value for this message
#   If we don't have a time
#    Add error message and reloop
#   Handle all the stuff needed for this file, reloop if ok
#   Return now indicating error

        my $time = _epoch( \$message );
        unless ($time) {
#          $self->_add_error( "Could not determine originating time of message at line $start in $mbox" );
          next;
        }
        next if _handle_file($self,$directory,$name,$message,$time,\%ordinal);
        return '';
      }
    }
  }

# Finish up the adding process
# Restore the original directory
# Remove files to be removed
# Return indicating success

  _finish_add( $self,$directory,$name,\%ordinal,$rfc822,$docseq );
  chdir( $cwd );
  unlink( @unlink ) if @unlink;
  return 1;
} #add_mbox

#------------------------------------------------------------------------

#  IN: 1 Net::NNTP object for fetching news messages from
#      2 (optional) reference to subroutine to create Net::NNTP object
# OUT: 1 whether successful
#      2 possibly adapted Net::NNTP object

sub add_news {

# Obtain the object
# Obtain the Net::NNTP object
# Obtain the way to make a Net::NNTP object

  my $self = shift;
  my $nntp = shift;
  my $newnntp = shift;

# Obtain the class
# Obtain the RFC822 object if any
# Obtain the Docseq object if any

  my $class = ref($self);
  my $rfc822 = $self->{$class.'::rfc822'} || '';
  my $docseq = $self->{$class.'::docseq'} || '';

# Obtain the original directory
# Obtain the directory to work in
# If failed to move to right directory
#  Add error and return
# Obtain the base name of the tarfiles to work with

  my $cwd = cwd;
  my $directory = $self->directory;
  unless (chdir( $directory )) {
    $self->_add_error( "Cannot chdir to $directory" );
    return;
  }
  (my $newsgroup = $directory) =~ s#^.*/##;

# Initialize the hash with ordinals
# Initialize number of messages
# Obtain the ordinal number of first and last message to fetch

  my %ordinal;
  my $messages = 0;
  my ($first,$last);
  ($first,$last,$nntp) = _resync_news( $self,$nntp,$newsgroup,$newnntp );

# For all of the messages
#  Obtain the message
#  Reloop if nothing there (probably removed from server)

  for (my $i = $first; $i <= $last; $i++) {
    my $message = $nntp->article( $i );
    next unless $message;

#   Attempt to obtain a time value for this message
#   If we don't have a time
#    Add error message and reloop

    my $time = _epoch( $message );
    unless ($time) {
#      $self->_add_error( "Could not determine originating time of message $i in $newsgroup" );
      next;
    }

#   If handling all the stuff needed for this file was ok
#    Increment number of messages
#    And reloop
#   Return now indicating error

    if (_handle_file($self,$directory,$newsgroup,$message,$time,\%ordinal)) {
      $messages++;
      next;
    }
    return wantarray ? ('',$nntp) : '';
  }

# Finish up the adding process
# Restore the original directory
# Return indicating success

  _finish_add( $self,$directory,$newsgroup,\%ordinal,$rfc822,$docseq );
  chdir( $cwd );
  return wantarray ? ($messages,$nntp) : $messages;
} #add_news

#------------------------------------------------------------------------

# OUT: 1 exit status of "rm"

sub clean {

# Obtain the work directory from the object
# Clean out directory name if attempt at bad stuff

  my $work = shift->work;
  $work =~ s#^(?:/|/\w+)$##;

# Return now if we don't have a directory
# Return now if it is not a directory
# Remove everything in the directory and return the exit code

  return unless length($work);
  return unless -d $work;
  return system( "rm -rf $work/*" );
} #clean

#------------------------------------------------------------------------

#  IN: 1 regular expression limiting the dates from which to count files
#      2 reference to a hash: key = date, value = [last mod,count]
# OUT: 1 total number of files

sub count {

# Obtain the object
# Obtain the constraint
# Obtain the external hash reference
# Return with the number of entries if there is no external hash reference

  my $self = shift;
  my $constraint = shift || '';
  my $hash = shift;
  return scalar @{$self->ids( $constraint )} unless $hash;

# Obtain the directory
# Obtain the name
# Add the RFC subdirectory
# Initialize the number of messages

  my $directory = $self->directory;
  (my $name = $directory) =~ s#^.*/##;
  $directory .= '/rfc';
  my $messages = 0;

# For all of the datestamps according to this constraint
#  Reloop if there is no tarfile for it
#  Obtain the last modified info from the tarfile
#  If there is an entry in the hash already
#   If the tarfile didn't change
#    Increment number of messages and reloop

  foreach my $datestamp (@{$self->datestamps( $constraint )}) {
    next unless -e "$directory/$datestamp.$name.tar.gz";
    my $thistime = (stat(_))[9];
    if (exists( $hash->{$datestamp} )) {
      if ($thistime == $hash->{$datestamp}->[0]) {
        $messages += $hash->{$datestamp}->[1];
        next;
      }
    }

#  Obtain the number of messages
#  Set the entry in the hash
#  Increment number of messages

    my $thismessages = @{$self->ids( $datestamp )};
    $hash->{$datestamp} = [$thistime,$thismessages];
    $messages += $thismessages;
  }

# Return the number of messages

  return $messages;
} #count

#------------------------------------------------------------------------

#  IN: 1 regular expression limiting the dates from which to count files
# OUT: 1 total number of files

sub count_storable {

# Obtain the object
# If we didn't try to check for Storable yet
#  Attempt to load Storable
#  Set flag if still not successful
# Return result of ordinary count if Storable is not available

  my $self = shift;
  unless (defined($Storable::VERSION)) {
    eval {require Storable};
    $Storable::VERSION ||= '';
  }
  return $self->count( shift ) unless $Storable::VERSION;

# Create the filename we need to look for
# Initialize the hash ref
# If the frozen version of the hash already exists
#  Make sure we slurp always
#  If we could open a pipe to that file
#   Obtain the hash ref from it
#   Close the pipe

  my $filename = $self->directory.'/count.gz';
  my $hash;
  if (-e $filename) {
    local $/ = undef;
    if (my $handle = $self->openfile( "gunzip --stdout $filename |" )) {
      $hash = Storable::fd_retrieve( $handle );
      close( $handle );
    }
  }

# Make sure that we have a have ref if something went wrong
# Perform the normal count, but with a hash ref

  $hash ||= {};
  my $count = $self->count( shift,$hash );

# Make sure that the file exists with the right ownerships
# If we can save the result, we can open a pipe
#  Write the hash to the file using a pipe
#  Close the pipe
# Return what we found

  $self->openfile( $filename,'>' ) unless -e $filename;
  if (my $handle = $self->openfile( "|gzip --stdout >$filename" )) {
    Storable::store_fd( $hash,$handle );
    close( $handle );
  }
  return $count;
} #count_storable

#------------------------------------------------------------------------

#  IN: 1 regular expression limiting the dates to return
# OUT: 1 reference to datestamps of dates in this targz

sub datestamps {

# Obtain the object
# Obtain the constraint (if any)
# Return now with that datestamp only if it is a simple datestamp constraint

  my $self = shift;
  my $constraint = shift || '';
  return [$constraint] if $constraint and $constraint =~ m#^\d{8}$#;

# Obtain the directory name
# Obtain the list of datestamps
# Just keep the ones we really want if there is a constraint
# Return a reference to the list

  my $directory = $self->directory;
  my @date = map {m#(\d{8}).*?\.tar\.gz$#; $1} <$directory/rfc/*.tar.gz>;
  @date = grep( m#$constraint#,@date ) if $constraint;
  return \@date;
} #datestamps

#------------------------------------------------------------------------

# OUT: 1 Targz directory

sub directory { shift->_class_variable( 'directory' ) } #directory

#------------------------------------------------------------------------

#  IN: 1 relative filename (from list returned by "ids")
# OUT: 1 absolute filename

sub filename {

# Obtain the object
# Obtain the relative filename
# Obtain the extension of the filename (if any)
# Return now if an unknown extension

  my $self = shift;
  my $filename = shift;
  my $extension = $filename =~ s#(\.\w+)$## ? $1 : '';
  return '' unless $extension =~ m#^(?:|\.xml)$#;

# Make sure the files are located in the appropriate directory
# Return error if the file is not there
# Return the absolute filename

  my $work = _splat_datestamp( $self,_datestamp( $filename ),$extension );
  return '' unless -e ($work .= "/$filename$extension");
  return $work;
} #filename

#------------------------------------------------------------------------

#  IN: 1 regular expression limiting the dates from which to return ids
# OUT: 1 reference to list of ids

sub ids {

# Obtain the object
# Obtain the constraint
# Fetch all dates
# Return now if nothing to do

  my $self = shift;
  my $constraint = shift || '';
  my @date = @{$self->datestamps( $constraint )};
  return unless @date;

# Obtain the directory
# Obtain the name
# Obtain the work directory name
# Obtain the current directory
# Initialize the list of files

  my $directory = $self->directory;
  (my $name = $directory) =~ s#^.*/##;
  my $work = $self->work;
  my @file;

# For all of the dates to be handled
#  If there is a work directory for the original files already
#   Obtain list of files from that directory, normalized and add that
#  Else (no work directory yet)
#   List the tarfile and add that
# Return the reference to the list

  foreach (@date) {
    if (-d "$work/$_") {
      push( @file,map {s#^.*/##; $_} <$work/$_/*> );
    } else {
      push( @file,@{_list_tarfile( $self,"$directory/rfc/$_.$name.tar.gz" )} );
    }
  }
  return \@file;
} #ids

#------------------------------------------------------------------------

# OUT: 1 name of targz

sub name {

# Obtain the directory
# Obtain the name part
# And return that

  my $directory = shift->directory;
  (my $name = $directory) =~ s#^.*/##;
  return $name;
} #name

#------------------------------------------------------------------------

#  IN: 1 new value for "no_auto_clean" action
# OUT: 1 current/old value for "no_auto_clean" action

sub no_auto_clean { shift->_class_variable('no_auto_clean',@_) } #no_auto_clean

#------------------------------------------------------------------------

#  IN: 1 new setting of "rm_original" flag
# OUT: 1 old/current setting of "rm_original" flag

sub rm_original { shift->_class_variable( 'rm_original',@_ ) } #rm_original

#------------------------------------------------------------------------

#  IN: 1 datestamp of which to obtain tarfile name
#      2 type of information (default: 'rfc')
# OUT: 1 name of tarfile

sub tarfile {

# Obtain the object
# Obtain the datestamp
# Return now if nothing to return

  my $self = shift;
  my $datestamp = shift;
  return '' unless $datestamp;

# Obtain the type of information
# Remove prefix period if any

  my $type = shift || 'rfc';
  $type =~ s#^\.##;

# Obtain the directory
# Obtain the name
# Return the name of the tarfile

  my $directory = $self->directory;
  (my $name = $directory) =~ s#^.*/##;
  return "$directory/$type/$datestamp.$name.tar.gz";
} #tarfile

#------------------------------------------------------------------------

#  IN: 1 RFC822 object to create XML with (default: from object)
#      2 Docseq object to create document sequence with (default: from object)
# OUT: 1 number of files processed

sub update_xml {

# Obtain the object
# Obtain the class
# Obtain the RFC822 object
# Obtain the Docseq object

  my $self = shift;
  my $class = ref($self);
  my $rfc822 = shift || $self->{$class.'::rfc822'};
  my $docseq = shift || $self->{$class.'::docseq'};

# Obtain the directory
# Obtain the name of the directory
# Add the new subdirectory to it
# If the directory exists already (assume aborted previous run)
#  Make sure there is no stuff in there
# Else (directory doesn't exist yet)
#  If making of directory failed
#   Add error and return

  my $directory = $self->directory;
  (my $name = $directory) =~ s#^.*/##;
  $directory .= "/xml.new";
  if (-d $directory) {
    unlink( <$directory/*> );
  } else {
    unless (mkdir( $directory,0777 )) {
      $self->_add_error( "Could not create '$directory': $!" );
      return 0;
    }
  }

# Obtain the current directory
# Change to the new directory
# Initialize the number of files done

  my $cwd = cwd;
  chdir( $directory );
  my $done = 0;

# For all of the dates available
#  Obtain the files for that date
#  For all of the files of this date
#   Obtain the absolute filename
#   Create a new Document from that
#   Remove the original file
#   Make sure the encoding is UTF-8
#   Write the XML
#   Add the XML to the document sequence if so expected

  foreach my $datestamp (@{$self->datestamps}) {
    my $ids = $self->ids( $datestamp );
    foreach (@{$ids}) {
      my $filename = $self->filename( $_ );
      my $document = $rfc822->Document( "$filename:$_",'filename' );
      unlink( $filename );
      $document->encoding( 'utf-8' );
      $document->write_file( "$_.xml" );
      $docseq->add( $document ) if $docseq;
    }

#  Create a tarfile of all the files now created
#  And remember how many we did

    _create_tarfile( $self,"$datestamp.$name",[map {"$_.xml"} @{$ids}] );
    $done += @{$ids};
  }

# Go back up to the original directory of this Targz
# Rename the current XML directory to the old XML directory
# Rename the new XML directory to the current one
# Move back to the directory we came from

  chdir( '..' );
  rename( 'xml','xml.old' ) if -d 'xml';
  rename( 'xml.new','xml' );
  chdir( $cwd );

  return $done;
} #update_xml

#------------------------------------------------------------------------

#  IN: 1 Docseq object to use (default: object's)
# OUT: 1 document sequence xml for entire Targz

sub xml {

# Obtain the object
# Obtain the docseq object if any
# Set the XML keep flag if we need to return something
# Set the docseq if not set yet and we are not supposed to return something
# Initialize the XML to be returned

  my $self = shift;
  my $docseq = shift;
  my $mustkeep = defined(wantarray);
  $docseq ||= $self->{ref{$self}.'::Docseq'} unless $mustkeep;
  my $xml = <<EOD;
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
EOD

# Obtain the directory to work in
# Obtain the base name of the tarfiles to work with
# Add the XML subdirectory
# If directory doesn't exist
#  Add error and return

  my $directory = $self->directory;
  (my $name = $directory) =~ s#^.*/##;
  $directory .= '/xml';
  unless (-d $directory) {
    $self->_add_error( "Directory $directory does not exist" );
    return '';
  }

# For all of the datestamps that are available
#  Attempt to create a pipe to all of the files
#  Return now if failed

  foreach my $datestamp (@{$self->datestamps}) {
    my $handle = $self->openfile(
     "$tar --extract --to-stdout --gunzip --file=$directory/$datestamp.$name.tar.gz |" );
    return '' unless $handle;

#  Initialize the XML for this iteration
#  Loop while there is something there
#   Add to XML unless it is an XML processor instruction
#  Close the pipe
#  Add the XML to the docseq if so specified
#  Add the XML to the total if we must have that returned

    my $thistime = '';
    while (<$handle>) {
      $thistime .= $_ unless m#^<\?xml.*?\?>$#;
    }
    close( $handle );
    $docseq->add( $thistime ) if $docseq;
    $xml .= $thistime if $mustkeep;
  }

# Return what we found (is almost nothing if called in void context)

  return <<EOD;
$xml</ntv:docseq>
EOD
} #xml

#------------------------------------------------------------------------

# OUT: 1 "work" directory

sub work { shift->_class_variable( 'work' ) } #work

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

sub DESTROY {

# Obtain the object
# Remove the directory if so specified

  my $self = shift;
  $self->clean unless $self->no_auto_clean;
} #DESTROY

#------------------------------------------------------------------------

# The following subroutines are for internal use only

#------------------------------------------------------------------------

#  IN: 1 object
#      2 name of tarfile to create/update (without .tar.gz extension)
#      3 reference to list of files names
# OUT: 1 whether successful

sub _create_tarfile {

# Obtain the object
# Obtain the tarfile
# Obtain the list of files

  my $self = shift;
  my $tarfile = shift;
  my $list = shift;

# Set the number of files to be added to the
# Set the ordinal number of the last file to add
# Set the type of action on the tar file
# For all the steps to take
#  Set the maximum for this step
#  Create the command to be executed
#  If creation or adaption of tarfile failed
#   Add error and return
#  Change type to appending

  my $step = 500;
  my $last = $#$list;
  my $type = '--create';
  for (my $i = 0; $i <= $last; $i += $step) {
    my $max = $i+$step <= $last ? $i + $step - 1 : $last;
    my $command =
     "$tar $type --remove-files --file=$tarfile.tar.new @{$list}[$i..$max]";
    if (my $exit = system( $command )) {
      $self->_add_error( "Command '$command' returned status $exit" );
      return '';
    }
    $type = '--append';
  }

# Create the command to zip the tarfile
# Zip the tarfile, if failed
#  Add error and return

  my $command = "gzip --best $tarfile.tar.new";
  if (my $exit = system( $command )) {
    $self->_add_error( "Command '$command' returned status $exit" );
    return '';
  }

# Return indicating success if rename to final file name successful
# Add error and return

  return 1 if rename( "$tarfile.tar.new.gz","$tarfile.tar.gz" );
  $self->_add_error( "Could not rename '$tarfile.tar.new.gz' to '$tarfile.tar.gz: $!" );
  return '';
} #_create_tarfile

#------------------------------------------------------------------------

#  IN: 1 epoch value
# OUT: 1 datestamp (YYYYMMDD)

sub _datestamp {

# Obtain the constituent parts of the epoch value
# Return formatted in the way that we want

  my ($second,$minute,$hour,$day,$month,$year) = gmtime( shift );
  return sprintf( '%04d%02d%02d',$year+1900,$month+1,$day );
} #_datestamp

#------------------------------------------------------------------------

#  IN: 1 file handle (closed upon exit in scalar context) or ref to message
# OUT: 1 timestamp
#      2 all headers read until date found

sub _epoch {

# Obtain the reference
# Initialize the line
# Initialize the time
# Initialize the close flag
# Initialize the handle
# Initialize the loop

  my $ref = shift;
  my $line = '';
  my $time = '';
  my $close = '';
  my $handle;
  my $next;

# If a message or header was passed
#  Create the handle
#  Set the routine to fetch the next line

  if (ref($ref) eq 'SCALAR') {
    $handle = bless $ref,'NexTrieve::handle';
    $next = sub {$handle->next};

# Elseif a list reference
#  Create the index
#  Set the routine to fetch the next line

  } elsif (ref($ref) eq 'ARRAY') {
    $handle = 0;
    $next = sub{$handle < @{$ref} ? $ref->[$handle++] : ''};

# Else (assume filehandle to read from)
#  Set the handle
#  Set the routine to fetch the next line
#  Set the flag to close the handle

  } else {
    $handle = $ref;
    $next = sub{<$handle>};
    $close = 1;
  }

# Make sure we have a local version of $_ (strange things happen otherwise)
# While there are lines to be read (obtaining it in $_)
#  Outloop if we reached end of headers
#  If this is a continuation line, losing any initial whitespace on the fly
#   Add it to what we already have, losing the delimiter on the fly

  local( $_ );
  while ($_ = &$next) {
    last if m#^\s+$#s;
    if (s#^\s+##) {
      $line .= " $_";

#  Else (new line)
#   If we have a line, making sure it is lowercase on the fly
#    If it is a line we think can have a valid date
#     If there is something that could be a date
#      Outloop if we got back something valid
#   Start a new line

    } else {
      if ($line = lc($line)) {
        if ($line =~ m#^(?:date:|from |nntp-posting-date:|received:|x-trace:)#) {
          if ($line =~ m#(\d+\s+\w+\s+\d+\s+\d+:\d+:\d+(?:\s+(?:[+-]?\d+|[a-zA-Z]+))?)#) {
            last if $time = _str2time( $1 );
          }
        }
      }
      $line = $_;
    }
  }

# Close the handle if so requested
# Return whatever we got

  close( $handle ) if $close;
  return $time;
} #_epoch

#------------------------------------------------------------------------

#  IN: 1 object
#      2 tarfile to extract file
#      3 directory to extract to (default: current directory)
# OUT: 1 reference of list of names of files

sub _extract_tarfile {

# Obtain the object
# Obtain the name of the tarfile
# Obtain the directory to extract to
# Turn it into a parameter if specified

  my $self = shift;
  my $tarfile = shift;
  my $todir = shift || '';
  $todir = " --directory=$todir" if $todir;

# If we want a list of filenames returned
#  If the tarfile exists
#   If we can open a pipe to the list of files while being extracted
#    Create a sorted list of filenames
#    Close the pipe
#    And return a reference to that
#  Return reference to an empty list

  if (defined(wantarray)) {
    if (-e $tarfile and -s _) {
      if (my $handle = $self->openfile(
       "$tar --extract --gunzip --verbose$todir --file=$tarfile|" )) {
        chomp( my @file = <$handle> ); @file = sort {$a <=> $b} @file;
        close( $handle );
        return \@file;
      }
    } 
    return [];
  }

# If the tarfile exists (and we don't want the list)
#  Create the command to extract the files
#  If there was something wrong extracting the files
#   Add error

  if (-e $tarfile and -s _) {
    my $command = "$tar --extract --gunzip$todir --file=$tarfile";
    if (my $exit = system( $command )) {
      $self->_add_error( "Command '$command' returned status $exit" );
    }
  }
} #_extract_tarfile

#------------------------------------------------------------------------

#  IN: 1 object
#      2 directory
#      3 name
#      4 reference to hash with date keys and id lists
#      5 RFC822 object
#      6 Docseq object

sub _finish_add {

# Obtain the parameters

  my ($self,$directory,$name,$ordinal,$rfc822,$docseq ) = @_;

# Change to the temp directory
# For all of the dates that were handling
#  Obtain datestamp format
#  If we're supposed to create XML from the messages
#   For all of the messages of this date
#    Create a NexTrieve::Document of it
#    Make sure the encoding is UTF-8
#    Write it with the extension ".xml"
#    Add it to the document sequence if so requested

  chdir( "$directory/temp" );
  foreach my $date (sort keys %{$ordinal}) {
    my $datestamp = _datestamp( $date );
    if ($rfc822) {
      foreach my $filename (@{$ordinal->{$date}}) {
        my $document = $rfc822->Document($filename,'filename',{name => $name});
        $document->encoding( 'utf-8' );
        $document->write_file( "$filename.xml" );
        $docseq->add( $document ) if $docseq;
      }

#   Return indicating failure if tarfile could not be made
#   Update the splat directory if that already existed

      return '' unless _create_tarfile(
       $self,
       "$directory/xml/$datestamp.$name",
       [map {"$_.xml"} @{$ordinal->{$date}}]
      );
      _splat_datestamp( $self,$datestamp,'.xml',1 );
    }

#  Return if creation of tarfile was not successful
#  Update the splat directory if that already existed
# Remove the temp directory

    return '' unless _create_tarfile(
     $self,
     "$directory/rfc/$datestamp.$name",
     $ordinal->{$date}
    );
    _splat_datestamp( $self,$datestamp,'',1 );
  }
  rmdir( "$directory/temp" );
} #_finish_add

#------------------------------------------------------------------------

#  IN: 1 object
#      2 directory to work on
#      3 root name of tar files
#      4 original absolute file name/file contents
#      5 epoch value found in file
#      6 reference to hash with current ordinal numbers
#      7 RFC822 object (if any, just used as a flag)
# OUT: 1 whether successful

sub _handle_file {

# Obtain the parameters
# Calculate the base date info
# Calculate the temp directory

  my ($self,$directory,$name,$file,$time,$ordinal,$rfc822) = @_;
  my $date = $time - ($time % 86400);
  my $temp = "$directory/temp";

# If there is no list of files for this date yet
#  Attempt to make the temp directory if that doesn't exist yet
#  If failed to chdir to temp directory
#   Add error and return
   
  unless (exists($ordinal->{$date})) {
    mkdir( $temp,0777 ) unless -d $temp;
    unless (chdir( $temp )) {
      $self->_add_error( "Cannot chdir to $temp" );
      return '';
    }

#  Obtain the datestamp
#  Extract the tarfile with the original filenames
#  Extract the XML files if we're making XML
#  Move back to the original directory

    my $datestamp = _datestamp( $date );
    $ordinal->{$date} =
     _extract_tarfile( $self,"$directory/rfc/$datestamp.$name.tar.gz" );
    _extract_tarfile( $self,"$directory/xml/$datestamp.$name.tar.gz" )
     if $rfc822;
    chdir( $directory );
  }

# Calculate the ID to be used for this file
# Save that in the file list
# If we got a reference to a list
#  Splat the joined contents where it's supposed to be and return if successful
#  Add error

  my $id = @{$ordinal->{$date}} ? $ordinal->{$date}->[-1] + 1 : $date + 1;
  push( @{$ordinal->{$date}},$id );
  if (ref($file) eq 'ARRAY') {
    return 1 if $self->splat(
     $self->openfile( "$temp/$id",'>' ),join( '',@{$file} ) );
    $self->_add_error( "Error saving message to '$temp/$id': $!" );

# Elseif we got a direct message
#  Just splat the file where it's supposed to be and return if successful
#  Add error

  } elsif ($file =~ m#\n#s) {
    return 1 if $self->splat( $self->openfile( "$temp/$id",'>' ),$file );
    $self->_add_error( "Error saving message to '$temp/$id': $!" );

# Else (we've got to copy the file because it exists out there already)
#  Return now indicating success if copy of file to temp directory successful
#  Add error

  } else {
    return 1 if copy( $file,"$temp/$id" );
    $self->_add_error( "Error copying '$file' to '$temp/$id': $!" );
  }

# Return indicating failure

  return '';
} #_handle_file

#------------------------------------------------------------------------

#  IN: 1 object
#      2 tarfile to list files of
# OUT: 1 reference of list of names of files

sub _list_tarfile {

# Obtain the object
# Obtain the name of the tarfile

  my $self = shift;
  my $tarfile = shift;

# If the tarfile exists
#  If we can open a pipe to the list of files while being extracted
#   Create a sorted list of filenames and close the pipe
#   And return a reference to that
# Return reference to an empty list

  if (-e $tarfile and -s _) {
    if (my $handle =
     $self->openfile( "$tar --list --gunzip --file=$tarfile|" )) {
      chomp( my @file = <$handle> ); close( $handle );
      return \@file;
    }
  } 
  return [];
} #_list_tarfile

#------------------------------------------------------------------------

#  IN: 1 object
#      2 datestamp
# OUT: 1 reference to list with message-ID's

sub _message_ids {

# Obtain the object
# Obtain the datestamp
# Return now if nothing to do

  my $self = shift;
  my $datestamp = shift;
  return [] unless $datestamp;

# Obtain the work directory, making sure we have all the files of that date
# Initialize the list of Message-ID's
# For all of the files of that date
#  Attempt to open the file
#  Reloop if failed

  my $work = _splat_datestamp( $self,$datestamp );
  my @id;
  foreach my $filename (sort {$a <=> $b} <$work/*>) {
    my $handle = $self->openfile( $filename,'<' );
    next unless $handle;

#  While there are lines to be read
#   Reloop if not a message-ID line
#   Save the message-ID in the list and outloop
#  Close the handle

    while (<$handle>) {
      next unless m#^message-id:\s*<?(.*?)>?$#i;
      push( @id,$1 );
      last;
    }
    close( $handle );
  }

# Return a reference to the list of message-IDs

  return \@id;
} #_message_ids

#------------------------------------------------------------------------

#  IN: 1 object
#      2 Net::NNTP object
#      3 name of newsgroup (default: name of targz)
# OUT: 1 ordinal number of first message to fetch
#      2 ordinal number of last message to fetch
#      3 (possibly adapted) Net::NNTP object

sub _resync_news {

# Obtain the object
# Initialize the Net::NNTP object to work on
# Obtain the newsgroup name

  my $self = shift;
  my $nntp = shift;
  my $newsgroup = shift || $self->name;

# Obtain the number of articles and the ordinal numbers
# If we didn't get any information at all (assume stale NNTP object)
#  If there is code to create a new NNTP object
#   Obtain the new NNTP object
#   Obtain articles and ordinals if there is a new NNTP object
#  Return now if nothing to be done

  my ($articles,$first,$last) = $nntp ? $nntp->group( $newsgroup ) : ();
  if (!defined($articles)) {
    if (my $newnntp = shift) {
      $nntp = &{$newnntp};
      ($articles,$first,$last) = $nntp->group( $newsgroup ) if $nntp;
    } 
    return (0,-1,$nntp) unless $articles;
  }

# Initialize the hash of headers fetched
# Initialize the hash of associated times
# Obtain the available datestamps
# Remember the last one

  my %head;
  my %time;
  my @datestamp = @{$self->datestamps};
  my $lastdate = $datestamp[-1];

# If successful in obtaining the header of the first message
#  If successful in obtaining the time from that header
#   Return now if that time is after what we have (a hole in the message stream)

  if (my $head = $head{$first} ||= $nntp->head( $first )) {
    if (my $time = $time{$first} ||= _epoch( $head )) {
      return ($first,$last,$nntp) if _datestamp( $time ) > $lastdate;
    }
  }

# Initialize the datestamp
# Initialize the message to start checking
# If we can obtain a header of this message
#  If we can obtain a time for this header
#   Convert to datestamp

  my $datestamp = 0;
  my $check = $last;
  if (my $head = $head{$check} ||= $nntp->head( $check )) {
    if (my $time = $time{$check} ||= _epoch( $head )) {
      $datestamp = _datestamp( $time );
    }
  }

# If we're not on the right date yet
#  Initialize the message number that was last checked
#  Initialize the initial number that will be checked

  if ($datestamp != $lastdate) {
    my $lastchecked = 0;
    $check = int(($last+$first)/2);

#  Initialize the low mark
#  Initialize the high mark
#  While we still need to continue checking
#   Remember which one we're checking now

    my $low = $first;
    my $high = $last;
    while ($check != $lastchecked and $check <= $high) {
      $lastchecked = $check;

#   If successful in obtaining a reference to the header of that message
#    If successful in obtaining the time of the message
#     Convert to datestamp
#     Outloop if we're on the right date or we're at the end of the area
#     If too low now
#      Move to half of upper half and set new low mark
#     Elseif too high now
#      Move to lower half and set new high mark
#     Reloop
#   Move to the next message (no message with this number)

      if (my $head = $head{$check} ||= $nntp->head( $check )) {
        if (my $time = $time{$check} ||= _epoch( $head )) {
          $datestamp = _datestamp( $time );
          last if $datestamp == $lastdate or $check == $high;
          if ($datestamp < $lastdate) {
            ($low,$check) = ($check,int(($high+$check)/2));
          } elsif ($datestamp > $lastdate) {
            ($high,$check) = ($check,int(($check+$low)/2));
          }
          next;
        }
      }
      $check++;
    }
  }

# If we're on the right date now
#  While there are messages to check
#   If successful in obtaining the header of the next message
#    If successful in obtaining a time from that
#     Outloop if we're now on a different date
#   Increment checked message number

  if ($datestamp == $lastdate) {
    while ($check < $last) {
      if (my $head = $head{$check+1} ||= $nntp->head( $check+1 )) {
        if (my $time = $time{$check+1} ||= _epoch( $head )) {
          last if _datestamp( $time ) != $lastdate;
        }
      }
      $check++;
    }
  }

# Initialize the list with message id's
# While there are still messages to check
#  If successful in obtaining the header of this message
#   If successful in obtaining the time of this message
#    If there is a message-id in this message
#     Obtain the datestamp of the time
#     Return now if two days before the last date that we have

  my %ids;
  while ($check >= $first) {
    if (my $head = $head{$check} ||= $nntp->head( $check )) {
      if (my $time = $time{$check} ||= _epoch( $head )) {
        if (my ($id) = grep( s#^message-id:\s*<?(.*?)>?\n$#$1#si,@{$head} )) {
          my $datestamp = _datestamp( $time );
          return ($check+1,$last,$nntp) if $datestamp < $lastdate-1;

#     Obtain the message-id:s that we have for this datestamp
#     For all of the ID's of this datestamp
#      Return starting from the next if we know about this message-id
#  Move to the previous message

          my @id = @{$ids{$datestamp} ||= _message_ids( $self,$datestamp )};
          foreach (@id) {
            return ($check+1,$last,$nntp) if $_ eq $id;
          }
        }
      }
    }
    $check--;
  }

# Return the result, do them all

  return ($first,$last,$nntp);
} #_resync_news

#------------------------------------------------------------------------

#  IN: 1 object
#      2 datestamp to splat
#      3 extension (including period) to use
#      4 flag: splat only if directory already exists
# OUT: 1 directory to which was splatted

sub _splat_datestamp {

# Obtain the object
# Obtain the datestamp
# Obtain the extension
# Obtain the renew flag

  my $self = shift;
  my $datestamp = shift;
  my $extension = shift || '';
  my $renew = shift;

# Obtain the work directory
# Adapt to the final work directory
# If we're supposed to renew only existing directories
#  Return now if the directory does not exist yet
# Elseif the directory exists (and not renewing only)
#  Return now

  my $work = $self->work;
  $work .= "/$datestamp$extension";
  if ($renew) {
    return $work unless -d $work;
  } elsif (-d $work) {
    return $work;
  }

# Attempt to create that directory
# If the subdirectory exists now
#  Extract all the files from that directory
# Else (could not chdir to the directory)
#  Add error
# Return the directory to which we extracted

  mkdir( $work,0777 );
  if (-d $work) {
    _extract_tarfile( $self,$self->tarfile( $datestamp,$extension ),$work );
  } else {
    $self->_add_error( "Directory '$work' does not exist" );
  }
  return $work;
} #_splat_datestamp

#------------------------------------------------------------------------

#  IN: 1 string to be scanned for date/time spec
# OUT: 1 epoch time (empty string if not found)

sub _str2time {

# Obtain the date to work with
# Initialize the time variable

  my $date = shift;
  my $time;

# Return now if we found a time
# Perform some heuristics to often occurring errors in date strings

  return $time if $time = Date::Parse::str2time( $date );
  $date =~ s#^(\w+,)(\w)#$1 $2#;
  $date =~ s#(\d+)(\+\d+)$#$1 $2#;

# Return now if we found a time this time
# Return with nothing if there is no timezone specification at the end
# Return now if there is nothing left to check
# Do it again without the timezone spec and return the result

  return $time if $time = Date::Parse::str2time( $date );
  return '' unless $date =~ s#\s+[a-zA-Z]+$##;
  return '' unless $date;
  return Date::Parse::str2time( $date ) || '';
} #_str2time

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Targz - create and maintain Targz archives

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $targz = $ntv->Targz( | {method => value} );

 # specifying the conversion to XML
 $rfc822 = $ntv->RFC822( {method => value} );
 $targz->RFC822( $rfc822 );

 # adding to archive and creating new XML files from seperate message files
 $targz->add_file( <files> );

 # adding to archive and creating new XML files from mbox files
 $targz->add_mbox( <mboxes> );

 # adding and creating new XML and automatically index document sequence
 $targz->Docseq( $ntv->Index( $resource )->Docseq );
 $targz->add_file( <files> );
 $targz->Docseq->done;

 # updating XML with new specifications
 $targz->update_xml( $rfc822 );

 # updating XML and automatically re-index
 $targz->update_xml( $rfc822,$ntv->Index( $resource )->Docseq );

 # re-index all XML
 $targz->xml( $ntv->Index( $resource )->Docseq );

 # obtain document sequence XML
 $xml = targz->xml;

=head1 DESCRIPTION

The Targz object of the Perl support for NexTrieve.  Do not create
directly, but through the Targz method of the NexTrieve object;

=head1 YET ANOTHER ARCHIVE

The Targz archive is basically just another way of archiving RFC822 messages.
The names comes from the fact that it internally uses "tar"-files that are
"gz"ipped for storage of the messages.

Apart from being able to archive messages, it can also save other
representations of those messages: currently only one alternative method
is allowed, namely the XML format as used by NexTrieve document sequences.

The NexTrieve::Targz module implements the Targz archive.  It was
developed internally at NexTrieve for an initial version of the News Search
Engine of http://www.search.nl .

When a message is added to the Targz archive (also referred to as "targz"),
the header of the message is read to determine the origination date of the
message.  Messages of which no origination date can be determined, can B<not>
be added to the targz.  The origination date is determined by looking at the
"From ", "Date:" and any other header that has a ";..." comment field.

An internal ID is assigned to the message.  This internal ID is calculated
by taking the epoch value of midnigh GMT of the date of the message and adding
an ordinal number to it.  So the ID of the first message is in fact the
epoch value of one second past midnight, the second message two seconds, etc.
This internal ID value has the advantage that it will fit in 4 bytes for quite
some years to come, it is unique and it can be easily used in constraints that
have a granularity of a day.

Messages that originated on the same date are stored in the same tarfile,
which is stored gzipped to save space.  Up to 86399 messages can be stored
for a single date, which seems enough for even the most busy newsgroup.

To be able to access single messages, a tarfile of a specific date is
automatically extracted completely whenever the absolute filename of a message
is requested.  In benchmarks it was shown that there is hardly any difference
in CPU-usage between extracting a single message or all messages.  By
extracting all messages of a date, it is possible to use the existence of
the directory in which they were extracted as a flag.

The Targz archive is a compromise between simplicity, space used to store
messages and being able to access them quickly.  Older versions of this
software that were used internally at NexTrieve, used a monthly tarfile for
low-volume newsgroups.  But since the invention of super-economic file-systems
such as ReiserFS (which is B<highly recommended> as the file system of choice
for storing Targz archives on), the overhead of having a single tarfile per
date seems to be more than bearable, especially compared to the simplicity it
creates.

Apart from the tarfiles that are created, no external files are being kept.
Ordinal numbers for messages are determined by the files that are already in
a tarfile and nothing else.

Internally at NexTrieve, this archive format is in use for storing over
65 million messages from over 10000 textual(non-binary) newsgroups in about
50 Gigabyte of diskspace, with about 250000 messages being added each day.
At the same time, the XML generated for these messages is being served as
HTML on a web-server.

=head1 PREREQUISITES

Currently a "tar" program that understands the following parameters B<must>
be available for this module to operate correctly:

 --append        append to existing tarfile
 --create        create new tarfile
 --directory=    extract files to indicated directory
 --extract       extract files from archive
 --file=         specify name of tarfile to work on
 --gzip          filter tarfile through "gzip"
 --gunzip        filter tarfile through "gunzip"
 --list          list filenames of files stored in tarfile
 --remove-files  remove original files upon storing in tarfile
 --to-stdout     extract files to STDOUT
 --verbose       perform action verbosely (list files being extracted)

Currently a "gzip" program that understands the following parameters B<must>
be available for this module to operate correctly:

 --best          use best compression possible

=head1 OBJECT METHODS

The following methods return objects.

=head2 Docseq

 $targz->Docseq( | $docseq, | {method => value} ;
 $docseq = $targz->Docseq;

The "Docseq" method allows you to access the NexTrieve::Docseq object that
lives inside of the NexTrieve::Targz object.

The first optional input parameter is the NexTrieve::Docseq object that should
be used by the NexTrieve::Targz object.  The current NexTrieve::Docseq object
is assumed if none is specified.  A new one is created if none was associated
with the object before.

A reference to a method-value pair hash to be applied to the NexTrieve::Docseq
object can be specified as the second input parameter.

For more information, see the documentation of the NexTrieve::Docseq module
itself.

=head2 Resource

 $resource = $mbox->Resource( | {method => value} );

The "Resource" method allows you to create a NexTrieve::Resource object from
the internal structure of the NexTrieve::L<RFC822>.pm object that lives inside
of the NexTrieve::Targz object.

For more information, see the documentation of the NexTrieve::RFC822 and
NexTrieve::Resource modules itself.

=head2 RFC822

 $targz->RFC822( | $rfc822, | {method => value} ;
 $rfc822 = $targz->RFC822;

The "RFC822" method allows you to access the NexTrieve::RFC822 object that
lives inside of the NexTrieve::Targz object.

The first optional input parameter is the NexTrieve::RFC822 object that should
be used by the NexTrieve::Targz object.  The current NexTrieve::RFC822 object
is assumed if none is specified.  A new one is created if none was associated
with the object before.

A reference to a method-value pair hash to be applied to the NexTrieve::RFC822
object can be specified as the second input parameter.

For more information, see the documentation of the NexTrieve::RFC822 module
itself.

=head1 OTHER METHODS

The following methods change aspects of the NexTrieve::Targz object.

=head2 add_file

  $targz->add_file || die "could not add *.new files\n";;
  $targz->add_file( <files> ) || die "could not add files\n";;

The "add_file" method allows you to add RFC822 messages that are stored in
seperate files to the targz.  Returns true if successful.

The input parameters can either be filenames or references to lists with
filenames.  If no input parameters are specified, all files with the extension
".new" that are stored in the L<directory> will be assumed.

If the L<rm_original> method was previously called with a true value, then the
files specified will be deleted on successful execution of this method.

=head2 add_mbox

  $targz->add_mbox( <mboxes> ) || die "could not add mboxes\n";;

The "add_mbox" method allows you to add RFC822 messages that are stored in
in one or more Unix mailboxes to the targz.  Returns true if successful.  If
the L<rm_original> method was previously called with a true value, then the
files specified will be deleted on successful execution of this method.

=head2 add_news

  $targz->add_news( $nntp ) || die "could not add news\n";

  ($messages,$nntp) = $targz->add_news( $nntp,\&create_NNTP );
  die "could not add news\n" unless $messages =~ m#^\d+$#;

The "add_news" method allows you to add RFC822 messages from a news (NNTP)
server.

The first input parameter specifies the Net::NNTP object that should be used to
obtain messages from the newsgroup of the L<name> of the targz.

The optional second input parameter specifies a reference to an (anonymous)
subroutine that can be called to create the Net::NNTP object.  This is
especially handy when reading a lot of newsgroups with the same Net::NNTP
object: some news servers let the connection go stale after a while: by
specifying this parameter you allow the add_news method to recover from such
a situation automatically.

Returns the number of messages that were successfully obtained in a scaler
context.  In a list context, the second output parameter is the possibly
adapted Net::NNTP object that was passed as the first input parameter.

=head2 clean

 $exit = $targz->clean;

The "clean" method cleans the temporary directory in use by the object.  It
is usually called automatically when the object is DESTROYed, unless inhibited
by a call to the L<no_auto_clean> method.

It returns the exit status of the system's "rm" command.

=head2 count

 $all = $targz->count;
 $some = $targz->count( 'regexp' );
 $oneday = $targz->count( datestamp );
 $stored = $targz->count( '',$hashref );

The "count" method returns the number of messages in the targz.  The amount
can be for the whole targz or constraint by a regular expression (as used in
a "grep()") or for just a single date (if a datestamp is specified).

The optional second input parameter is a reference to a hash.  This hash will
be filled with a key for each datestamp for which files are found.  The value
of the key in the hash is a reference to a list which currently contains two
value: the last modified time of the tarfile and the number of messages in it.
If the tarfile is deemed to not have changed, the tarfile itself will not be
read but instead the value found in the value will be used.  The hash reference
can e.g. be stored in the directory with the Storable module, which is what the
L<count_storable> method does, or can be stored in any other database backend
that you might desire.

Use the L<ids> method to find out the actual ID's of the messages.

=head2 count_storable

 $all = $targz->count_storable;
 $some = $targz->count_storable( 'regexp' );
 $oneday = $targz->count_storable( datestamp );

The "count_storable" method is similar to the L<count> method, but it uses a
hash that is stored in an external file ("count.gz" in the L<directory>
directory) to remember which tarfiles were counted already before.  If the
Storable module is not available, calling this method will still work but
the counting will be much slower.

The "count_storable" method returns the number of messages in the targz.  The
amount can be for the whole targz or constraint by a regular expression (as
used in a "grep()") or for just a single date (if a datestamp is specified).

=head2 datestamps

 foreach (@{$targz->datestamps}) {

The "datestamps" method returns a reference to a list of datestamps of the
dates of which the targz contains messages.  Datestamps are in the form
"YYYYMMDD".  They are always ordered in ascending order.  A datestamp can
be used as an input parameter to L<files>.

=head2 directory

 $directory = $targz->directory;

The "directory" method returns the directory that is used by the
NexTrieve::Targz object to permanently store information.  The directory is
created when the NexTrieve::Targz object is created.

=head2 filename

 $rfc = $targz->filename( $id );
 $xml = $targz->filename( "$id.xml" );
 system( "cat $xml" );

The "filename" method returns an absolute filename for the message specified
by the input parameter.  As a side-effect, extracts all messages of the same
date into a temporary directory.

The input parameter is the id of which to obtain the absolute filename.  It
can be suffixes by the string ".xml" to indicate that the XML version of the
message is requested.  The id values can be obtained by a call to L<ids>.

Returns the empty string if there is no message (or XML-version of that
message) available.

=head2 ids

 $all = $targz->ids;
 $some = $targz->ids( 'regexp' );
 $oneday = $targz->ids( datestamp );

The "ids" method returns a reference to a list of ID's of the messages in the
targz.  The list can be complete or constraint by a regular expression (as
used in a "grep()") or for just a single date (if a datestamp is specified).

Use the L<filename> method to find out the absolute filename of a message to
be able to get at its contents.

=head2 name

  $name = $targz->name;

The "name" method returns the name of the targz.  This is the same as the
name of the final subdirectory on which the targz works.

=head2 no_auto_clean

 $targz->no_auto_clean( 1 );
 $no_auto_clean = $targz->no_auto_clean;

The "no_auto_clean" method specifies whether the temporary directory that is
used by the object should be L<clean>ed when the object is DESTROYed.  By
default, the object cleans the temporary directory.  A true value indicates
that the temporary directory should B<not> be removed when the object is
DESTROYed.  This is generally only useful in debugging situations.

=head2 rm_original

 $targz->rm_original( 1 );
 $rm_original = $targz->rm_original;

The "rm_original" method specifies whether files that are specified to be added
(with either the L<add_file> or L<add_mbox> method) are automatically removed
from the file system upon successful adding.

=head2 tarfile

 $tarfile = $targz->tarfile( '20020323' );
 $tarfile = $targz->tarfile( $datestamp,'xml' );

The "tarfile" method returns the absolute name of the tarfile that contains
the files of a given date.  It is only necessary if you want to do some
low level action on the tarfile.

The first input parameter specifies the datestamp of the date of which you
want to know the tarfile name.

The optional second input parameter specifies which type of information you
want the tarfile name of.  Two values are currently supported: 'rfc' and 'xml'.
The value 'rfc' will be assumed if this input parameter is not specified.

=head2 update_xml

 $files = $targz->updatexml( | $rfc822, | $docseq );

The "update_xml" method reads all the messages in the targz and creates new
XML for them, either using the NexTrieve::L<RFC822> object that lives inside
the NexTrieve::Targz object, or with a specific one that is specified.

The second input parameter specifies the L<Docseq> object that should also be
used to process all newly created document XML.  The NexTrieve::Docseq object
that lives inside the NexTrieve::Targz object will be assumed if none is
specified.

The number of files that were processed, is returned.

=head2 work

 $work = $targz->work;

The "work" method returns the work directory that is used by the
NexTrieve::Targz objects that are in this process.  The work directory is
created when the NexTrieve::Targz object is created.  The location of the
work directory is determined by the Tmp setting of the NexTrieve::Targz
object (which is inherited from the NexTrieve object).

=head2 xml

 $xml = $targz->xml;
 $targz->xml( | $docseq );

The "xml" method either returns the document sequence XML of the entire
targz, or processes the document XML of all the messages in the targz with
the L<Docseq> object specified.  When called in a void context, the Docseq
object of the targz will be assumed, or a new one will be created.  When
called in a scalar context, no Docseq object will be used unless specifically
specified.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 SUPPORT

NexTrieve is no longer being supported.

=head1 COPYRIGHT

Copyright (c) 1995-2003 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

The NexTrieve.pm and the other NexTrieve::xxx modules.

=cut
