package NexTrieve;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::ISA = qw();
$NexTrieve::VERSION = '0.02';

# Use the external modules that we need

use IO::Socket ();

# Initialize reference to MD5 signature maker if already loaded

my $makemd5;
$makemd5 = \&Digest::MD5::md5_hex if defined( $Digest::MD5::VERSION );

# Create the character to entity conversion hash
# Create the list of characters for matching

my %char2entity = (
 '<'    => '&lt;',
 '>'    => '&gt;',
);
my $chars = join( '|',keys %char2entity );

# Initialize the known entity to name conversion

my %entity2name = (
 ''	=> 'amp',
 '#9'	=> '#9',	# little trick for catching TAB's
 amp	=> 'amp',
 apos	=> 'apos',
 gt	=> 'gt',
 lt	=> 'lt',
 quot	=> 'quot', 
 nbsp   => '#160',
 iexcl  => '#161',
 cent   => '#162',
 pound  => '#163',
 curren => '#164',
 yen    => '#165',
 brvbar => '#166',
 sect   => '#167',
 uml    => '#168',
 copy   => '#169',
 ordf   => '#170',
 laquo  => '#171',
 not    => '#172',
 shy    => '#173',
 reg    => '#174',
 macr   => '#175',
 deg    => '#176',
 plusmn => '#177',
 sup2   => '#178',
 sup3   => '#179',
 acute  => '#180',
 micro  => '#181',
 para   => '#182',
 middot => '#183',
 cedil  => '#184',
 sup1   => '#185',
 ordm   => '#186',
 raquo  => '#187',
 frac14 => '#188',
 frac12 => '#189',
 frac34 => '#190',
 iquest => '#191',
 Agrave => '#192',
 Aacute => '#193',
 Acirc  => '#194',
 Atilde => '#195',
 Auml   => '#196',
 Aring  => '#197',
 AElig  => '#198',
 Ccedil => '#199',
 Egrave => '#200',
 Eacute => '#201',
 Ecirc  => '#202',
 Euml   => '#203',
 Igrave => '#204',
 Iacute => '#205',
 Icirc  => '#206',
 Iuml   => '#207',
 ETH    => '#208',
 Ntilde => '#209',
 Ograve => '#210',
 Oacute => '#211',
 Ocirc  => '#212',
 Otilde => '#213',
 Ouml   => '#214',
 times  => '#215',
 Oslash => '#216',
 Ugrave => '#217',
 Uacute => '#218',
 Ucirc  => '#219',
 Uuml   => '#220',
 Yacute => '#221',
 THORN  => '#222',
 szlig  => '#223',
 agrave => '#224',
 aacute => '#225',
 acirc  => '#226',
 atilde => '#227',
 auml   => '#228',
 aring  => '#229',
 aelig  => '#230',
 ccedil => '#231',
 egrave => '#232',
 eacute => '#233',
 ecirc  => '#234',
 euml   => '#235',
 igrave => '#236',
 iacute => '#237',
 icirc  => '#238',
 iuml   => '#239',
 eth    => '#240',
 ntilde => '#241',
 ograve => '#242',
 oacute => '#243',
 ocirc  => '#244',
 otilde => '#245',
 ouml   => '#246',
 divide => '#247',
 oslash => '#248',
 ugrave => '#249',
 uacute => '#250',
 ucirc  => '#251',
 uuml   => '#252',
 yacute => '#253',
 thorn  => '#254',
 yuml   => '#255',
);

# Make sure that a true value is returned from -use-

1;

#-------------------------------------------------------------------------

# Following subroutines are for instantiating objects

#-------------------------------------------------------------------------

sub new {

# Find out what class we need to be blessing
# Create the object
# Bless the object

  my $class = shift;
  my $self = {};
  bless $self,$class;

# Set any parameters if they are specified
# Save version information in the object
# Return something that we can work with

  $self->Set( shift ) if $_[0];
  _class_variable( $self,qw(version 1.0) );
  return $self;
} #new

#-------------------------------------------------------------------------

#  IN: 1 path of collection
#      2 flag: whether to create
# OUT: 1 instantiated NexTrieve::Collection object

sub Collection { 'NexTrieve::Collection'->_new( @_ ) } #Collection

#-------------------------------------------------------------------------

#  IN: 1 filename or xml or NexTrieve::Resource object
#      2 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::Daemon object

sub Daemon { 'NexTrieve::Daemon'->_new( @_ ) } #Daemon

#-------------------------------------------------------------------------

#  IN: 1 ref to method/parameters hash
# OUT: 1 instantiated NexTrieve::Docseq object

sub Docseq { 'NexTrieve::Docseq'->_new_from_filename_xml( @_ ) } #Docseq

#-------------------------------------------------------------------------

#  IN: 1 ref to method/parameters hash
# OUT: 1 instantiated NexTrieve::Document object

sub Document { 'NexTrieve::Document'->_new( @_ ) } #Document

#-------------------------------------------------------------------------

#  IN: 1 filename or xml (optional)
# OUT: 1 instantiated NexTrieve::Hitlist object

sub Hitlist { 'NexTrieve::Hitlist'->_new_from_filename_xml( @_ ) } #Hitlist

#-------------------------------------------------------------------------

#  IN: 1 filename or xml or NexTrieve::Resource object
#      2 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::Search object

sub Index { 'NexTrieve::Index'->_new( @_ ) } #Index

#-------------------------------------------------------------------------

# OUT: 1 instantiated NexTrieve object

sub NexTrieve { _variable( shift,'Nextrieve' ) } #NexTrieve

#-------------------------------------------------------------------------

#  IN: 1 filename or xml (optional)
# OUT: 1 instantiated NexTrieve::Query object

sub Query { 'NexTrieve::Query'->_new_from_filename_xml( @_ ) } #Query

#-------------------------------------------------------------------------

#  IN: 1 filename
# OUT: 1 instantiated NexTrieve::Querylog object

sub Querylog { 'NexTrieve::Querylog'->_new( @_ ) } #Querylog

#-------------------------------------------------------------------------

#  IN: 1 reference to method/value pairs
# OUT: 1 instantiated NexTrieve::Querylog object

sub Replay { 'NexTrieve::Replay'->_new( @_ ) } #Replay

#-------------------------------------------------------------------------

# As a "class" method
#  IN: 1 filename or xml (optional)
# OUT: 1 instantiated NexTrieve::Resource object

# As an object method
#  IN: 1 new resource specification (filename or xml or object)
# OUT: 1 current/old resource specification

sub Resource {

# Obtain the object
# Obtain the class of the object
# Return a new object if called as a "class" method from the NexTrieve object

  my $self = shift;
  my $class = ref($self);
  return 'NexTrieve::Resource'->_new_from_filename_xml( $self,@_ )
   if $class eq 'NexTrieve';

# Obtain the resource specification
# Obtain the name of the field
# Obtain the current setting

  my $resource = shift || '';
  my $field = $class.'::Resource';
  my $old = $self->{$field};

# If we have a new specification
#  Obtain the ref type
#  If it is the right object or a server:port specification
#   Save that as resource

  if ($resource) {
    my $objectclass = ref($resource);
    if ($objectclass eq 'NexTrieve::Resource') {
      $self->{$field} = $resource;

#  Elseif it is a potential resource specification
#   Attempt to create a Resource Object out of that
#   If there were errors in the object
#    Copy the errors over
#   Else (no errors)
#    Save the object

    } elsif (!$objectclass or $objectclass eq 'HASH') {
      my $object = $self->NexTrieve->Resource( $resource );
      if (my @error = $object->Errors) {
        $self->_add_errors( @error );
      } else {
        $self->{$field} = $object;
      }

#   Else
#    Add error (not right object)

    } else {
      $self->_add_error( "Object must be a NexTrieve::Resource, not '$objectclass'" );
    }
  }

# Return the resource specification

  return $old;
} #Resource

#-------------------------------------------------------------------------

#  IN: 1 server:port or filename or xml or NexTrieve::Resource object
# OUT: 1 instantiated NexTrieve::Search object

sub Search { 'NexTrieve::Search'->_new( @_ ) } #Search

#-------------------------------------------------------------------------

# Following subroutines offer functionality with regards to fields in the object

#-------------------------------------------------------------------------

#  IN: 1 new setting for DieOnError (default: no change)
# OUT: 1 current/old setting for DieOnError

sub DieOnError { _variable( shift,'DieOnError',@_ ) } #DieOnError

#-------------------------------------------------------------------------

#  IN: 1 new setting for Encoding (default: no change)
# OUT: 1 current/old setting for Encoding

sub encoding {

# Obtain the object
# If there are new parameters
#  Obtain local copy of the class name
#  If there is version information (not virginal anymore)
#   Add error and return

  my $self = shift;
  if (@_) {
    my $class = ref($self);
    if ($class ne 'NexTrieve' and exists $self->{$class.'::version'}) {
      $self->_add_error( "Can only set encoding on untouched $class object" );
      return;
    }

#  Set the name of the field containing the encoding
#  If there is an encoding already
#   Add error and return

    my $field = $class.'::encoding';
    if (exists( $self->{$field} ) and $self->{$field}) {
      $self->_add_error(
       "Already encoded as '$self->{$field}', cannot change to '$_[0]'" );
      return;
    }

#  Obtain the encoding
#  If unkown encoding
#   Add error and return

    my $encoding = lc($_[0]);
    unless ($encoding =~ m#^(?:utf-8|utf-16|utf-32|us-ascii|iso-8859-1|iso-latin-1)#) {
      $self->_add_error( "$_[0] is an unknown encoding" );
      return;
    }
  }

# Return setting/returning whatever is needed

  return _class_variable_kill_xml( $self,'encoding',@_ );
} #encoding

#-------------------------------------------------------------------------

# OUT: 1..N errors accumulated so far and removed from object if in list context

sub Errors {

# Obtain the object
# Create the name of the field
# Initialize the list of errors

  my $self = shift;
  my $name = ref($self).'::Errors';
  my @error;

# If there are errors
#  Obtain them
#  Delete them from the object if we're returning the content of the errors
# Return whatever we found

  if (exists $self->{$name}) {
    @error = @{$self->{$name}};
    delete( $self->{$name} ) if wantarray;
  }
  return @error;
} #Errors

#-------------------------------------------------------------------------

#  IN: 1 new filename (default: no change)
# OUT: 1 current/old filename

sub filename {

# Obtain the object
# Obtain the class of the object
# Reset the File OK flag if there is  new filename
# Obtain the old value and possibly set the new one

  my $self = shift;
  my $class = ref($self);
  delete( $self->{$class.'::FILEOK'} ) if $_[0];
  _variable( $self,$class.'::filename',@_ );
} #Filename

#-------------------------------------------------------------------------

#  IN: 1..N names of methods to apply to object
# OUT: 1..N values returned by the methods

sub Get {

# Obtain the object
# Initialize the list of values
# Allow for non-strict references

  my $self = shift;
  my @value;
  no strict 'refs';

# If were supposed to return something
#  For all of the methods specified
#   Execute the method and return its value
#  Return the list of values

  if (defined(wantarray)) {
    foreach my $method (@_) {
      push( @value,scalar($self->$method()) );
    }
    return @value;
  }

# Obtain the namespace of the caller
# For all of the methods specified
#  Call the method and put the result in the caller's namespace

  my $namespace = caller().'::';
  foreach my $method (@_) {
    ${$namespace.$method} = $self->$method();
  }
} #Get

#-------------------------------------------------------------------------

#  IN: 1 new path specification
# OUT: 1 current/old path specification

sub NexTrievePath {

# Obtain the object
# Set and/or obtain the path
# Return the environment variable if it exists and is set

  my $self = shift;
  my $path = _variable( $self,'NexTrievePath',@_ ) || '';
  return $path unless defined(wantarray) and !$path;

# Set the base directory
# If there is no specific path in the environment, saving value on the fly
#  If the base exists as a directory
#   If there is a version specified, saving it on the fly
#    Set that as the directory

  my $base = $ENV{'NTV_BASE'} || '/usr/local/nextrieve';
  unless ($path = $ENV{'NTV_PATH'}) {
    if (-d $base) {
      if (my $version = $self->NexTrieveVersion) {
        $path = "$base/$version";

#   Elseif there is a bin directory
#    Set that as the directory

      } elsif (-d "$base/bin") {
        $path = "$base/bin";

#   Elseif there are numeric subdirectories, obtaining highest numbered
#    Set that as the directory

      } elsif (($version) =
       sort {$b cmp $a} map {$1 if m#/(\d+(?:\.\d+)+)$#} <$base/*>) {
        $path = "$base/$version";
      } 
    }
  }

# If we still don't have a path
#  For all of the directories in the PATH
#   Reloop if no NexTrieve search binary there
#   Set the path to that directory and outloop

  unless ($path) {
    foreach (split( ':',$ENV{'PATH'} || '' )) {
      next unless -x "$_/ntvsearch";
      $path = $_;
      last;
    }
  }

# Return what we found, saving in object on the fly

  return $self->{'NexTrievePath'} = $path;
} #NexTrievePath

#-------------------------------------------------------------------------

#  IN: 1 new version specification
# OUT: 1 current/old version specification

sub NexTrieveVersion {
 _variable( shift,'NexTrieveVersion',@_ ) } #NexTrieveVersion

#-------------------------------------------------------------------------

#  IN: 1 reference to a hash or list with values keyed to method names

sub Set {

# Obtain the object
# Obtain the reference
# Obtain the type of reference
# Allow for non-strict references

  my $self = shift;
  my $ref = shift;
  my $type = ref($ref);
  no strict 'refs';

# If we have a hash reference
#  For all of the methods specified
#   Execute the method with the given parameters

  if ($type eq 'HASH') {
    foreach my $method (keys %{$ref}) {
      $self->$method( ref($ref->{$method}) eq 'ARRAY' ?
       @{$ref->{$method}} : $ref->{$method} );
    }

# Elseif we have a list reference
#  While there are methods to be handled
#   Obtain the parameters
#   Execute the method with the given parameters

  } elsif ($type eq 'ARRAY') {
    while (my $method = shift( @{$ref} )) {
      my $parameters = shift( @{$ref} );
      $self->$method( ref($parameters) eq 'ARRAY' ?
       @{$parameters} : $parameters );
    }

# Else (we don't know what to do with it)
#  Add error

  } else {
   $self->_add_error( "Cannot handle value of type '$type'" );
  }
} #Set

#-------------------------------------------------------------------------

#  IN: 1 new setting for ShowErrorsAsWarnings (default: no change)
# OUT: 1 current/old setting for DieOnError

sub ShowErrorsAsWarnings {
 _variable( shift,'ShowErrorsAsWarnings',@_ ) } #ShowErrorsAsWarnings

#-------------------------------------------------------------------------

#  IN: 1 new temporary directory specification
# OUT: 1 current/old temporary directory specification

sub Tmp {

# Set and/or return the temporary directory

  return _variable( shift,'Tmp',@_ ) ||
          $ENV{'TMP'} ||
          '/tmp';
} #Tmp

#-------------------------------------------------------------------------

# OUT: 1 current setting for Version

sub version { _class_variable( shift,'version' ) } #version

#-------------------------------------------------------------------------

# Following subroutines offer general functionality

#------------------------------------------------------------------------

#  IN: 1 servername or IP address (defaults to "localhost")
# OUT: 1 random port number

sub anyport {

# Obtain the object
# Obtain the result of a random selection of a port (freed because out of scope)

  my $self = shift;
  my $port = IO::Socket::INET->new(
   Listen => 5,
   LocalAddr => (shift || 'localhost')
  )->sockport;

# Make sure the system's freed up the port
# Return it

  sleep( 1 );
  return $port;
} #anyport

#-------------------------------------------------------------------------

#  IN: 1 server:port or port specification
#      2 data to send to server:port
# OUT: 1 whatever was returned by the server

sub ask_server_port {

# Obtain the object
# Attempt to open a socket there
# Return now if failed

  my $self = shift;
  my $socket = $self->_socket( shift );
  return unless $socket;

#  Send the commands
#  Read the result and return (close socket upon going out of scope)

  print $socket scalar(shift);
  return join('',<$socket>); # is this the most efficient way memory wise?
} #ask_server_port

#-------------------------------------------------------------------------

#  IN: 1 server:port or port specification
#      2 data to send to server:port
#      3 file handle to write result to

sub ask_server_port_fh {

# Obtain the object
# Attempt to open a socket there
# Return now if failed

  my $self = shift;
  my $socket = $self->_socket( shift );
  return unless $socket;

# Obtain the query
# Obtain the handle
# If there is no handle
#  Add error and return

  my $query = shift;
  my $handle = shift;
  unless ($handle) {
    $self->_add_error( "Must have a handle to write output of socket to" );
    return;
  }

#  Send the commands
#  Read the result and return (close socket upon going out of scope)

  print $socket $query;
  print $handle $_ while <$socket>; # the most efficient way memory wise?
} #ask_server_port_fh

#-------------------------------------------------------------------------

#  IN: 1 server:port or port specification
#      2 data to send to server:port
#      3 filename to write result to

sub ask_server_port_file {

# Obtain the object
# Obtain the serverport
# Obtain the query

  my $self = shift;
  my $serverport = shift;
  my $query = shift;

# Obtain the filename
# If there is no filename
#  Add error and return
# Attempt to open the file (will be closed upon going out of scope)
# Return now if failed

  my $filename = shift;
  unless ($filename) {
    $self->_add_error( "Must have a filename to write output of socket to" );
    return;
  }
  my $handle = $self->openfile( $filename,'>' );
  return unless $handle;

# Return whatever was returned from the handle version

  return $self->ask_server_port_fh( $serverport,$query,$handle );
} #ask_server_port_file

#-------------------------------------------------------------------------

# IN/OUT: 1..N left-values to normalize
  
sub normalize {

# Get rid of the object if there is one

  shift if ref($_[0]);

# For all of the input parameters
#  Reloop if nothing to do
#  Make sure it is clean

  foreach (@_) {
    next unless $_;
    s#&(\#?\w*);?#ampersand( $1 )#sge;		# turn &xxx; into entities
    s#($chars)#$char2entity{$1}#sgo;		# turn <> into entities
    s#[\x00-\x08\x0b-\x1f\x80-\x9f]# #sg;	# remove iso-8859-1 illegals
  }

#  Subroutine for processing the ampersand
#   Obtain the string to check

  sub ampersand {
    my $string = shift;

#   If it was numeric
#    Return it if it is a valid code
#    Return special case if it is a TAB

    if ($string =~ m#^\#(\d+)$#) {
      return "&$string;" if chr($1) =~ m#^[\x09-\x0a\x20-\x7f\xa0-\xff]$#;
      return '&'.substr($string,0,2).';'.substr($string,2)
       if $string =~ m#^\#9#;

#    Start with the all numeric part of the entity
#    While there is someting to be processed
#     Return if what we now have is a legel character
#     Remove the last character

      my $substring = substr($string,1);
      while ($substring) {
        return "&#$substring;".substr($string,length($substring)+1)
         if chr($substring) =~ m#^[\x09-\x0a\x20-\x7f\xa0-\xff]$#;
        $substring =~ s#.$##;
      }

#   Elseif it was hexadecimal numeric
#    Start with the all hexadecimal part of the entity
#    While there is someting to be processed
#     Return if what we now have is a legel character
#     Remove the last character

    } elsif ($string =~ m#^x([\da-fA-F]+)$#) {
      my $substring = $1;
      while ($substring) {
        return "&x$substring;".substr($string,length($substring)+1)
         if chr(hex($substring)) =~ m#^[\x09-\x0a\x20-\x7f\xa0-\xff]$#;
        $substring =~ s#.$##;
      }

#   Else (not immediately known what to do)
#    Create a lower case version of the string
#    While there is something to check
#     If this is a known entity
#      Return the formal representation with whatever was not part of it
#     Remove last character from string to check

    } else {
      my $substring = lc($string);
      while ($substring) {
        if (my $name = $entity2name{$substring}) {
          return "&$name;".substr($string,length($substring));
        }
        $substring =~ s#.$##;
      }
    }

#   Return the string, prefixed by "&amp;" because not known

    return "&amp;$string";

  } #ampersand
} #normalize

#-------------------------------------------------------------------------

#  IN: 1..N parameters to open() function apart from handle specification
# OUT: 1 handle of opened file (undef if failed)

sub openfile {

# Obtain the object
# Create a handle
# Open the file and return its handle if successful

  my $self = shift;
  my $handle;

# why doesn't this work?
#  $handle = do { local *FH; *FH };
#  return $handle if open( $handle, @_ );

use IO::File (); # temporary solution
return $handle if $handle = IO::File->new( @_ );

# Add error to object
# And return empty handed

  $self->_add_error( "Could not open file '$_[0]': $!" );
  return;
} #openfile

#-------------------------------------------------------------------------

#  IN: 1 new user name or number
#      2 new group name or number (default: no change)
# OUT: 1 old/current user number
#      2 old/current group number

sub uidgid {

# Obtain the object
# Obtain the current values

  my $self = shift;
  my ($olduid,$oldgid) = ($>,$));

# Obtain the user id
# Convert to number if not a number already
# Set the UID if we have one

  my $uid = shift || '';
  $uid = getpwnam( $uid ) if $uid and $uid !~ m#^\d+$#;
  $> = $uid if $uid;

# Obtain the group id
# Convert to number if not a number already
# Set the GID if we have one

  my $gid = shift || '';
  $gid = getgrnam( $gid ) if $gid and $gid !~ m#^\d+$#;
  $) = "$gid $gid" if $gid;

# Return the previous values

  return wantarray ? ($olduid,$oldgid) : $olduid;
} #uidgid

#-------------------------------------------------------------------------

#  IN: 1 root of temporary filename (default: 'temp')
#      2 extension of temporary filename (default: 'xml')
# OUT: 1 absolute filename for temporary file for this object

sub tempfilename {

# Obtain the object
# Obtain the root name
# Obtain the file extension
# Obtain the id for this object
# Return the temporary filename

  my $self = shift;
  my $root = shift || 'temp';
  my $extension = shift || 'xml';
  my $id = $self =~ m#0x(\d+)# ? $1 : 'strange';
  return $self->Tmp."/$root.$$.$id.$extension";
} #tempfilename

#-------------------------------------------------------------------------

#  IN: 1 variable to untaint (change if in void context)
# OUT: 1 untainted value

sub untaint { 

# Get rid of the object if there are more than 1 parameters
# Get an untainted copy of the value in $1
# Return it if not in a void context
# Attempt to change the left-value directly

  shift if @_ > 1 and ref($_[0]) ;
  $_[0] =~ m#^(.*)$#s;
  return $1 if defined(wantarray);
  $_[0] = $1;
} #untaint

#------------------------------------------------------------------------

# Following subroutines are inheritable, not to be used by NexTrieve.pm itself

#------------------------------------------------------------------------

# OUT: 1 command last executed

sub command { $_[0]->{ref(shift).'::command'} } #command

#------------------------------------------------------------------------

#  IN: 1 new indexdir override
# OUT: 1 old/current indexdir override

sub indexdir { shift->_class_variable( 'indexdir',@_ ) } #indexdir

#------------------------------------------------------------------------

# OUT: 1 integrity report

sub integrity {

# Obtain the object

  my $self = shift;

# Obtain the index directory
# If there is no index directory
#  Add error and return

  my $indexdir = $self->indexdir || $self->Resource->indexdir || '';
  unless ($indexdir) {
    $self->_add_error( "Must know which index to check" );
    return;
  }

# Obtain local copy of the command and store in object
# Attempt to open a pipe
# Return now if failed

  my $command = $self->{ref($self).'::command'} =
   $self->NexTrievePath.'/ntvcheck';
  my $handle = $self->openfile( "$command $indexdir 2>/dev/null |" );
  return unless $handle;

# Initialize the report
# While there are lines to be read
#  Reloop if they're activity indicator fluff
#  Add line to report
# Return the final report

  my $report = '';
  while (<$handle>) {
    next if m#^\s*$# or m#^\.+#;
    $report .= $_;
  }
  return $report;
} #integrity

#------------------------------------------------------------------------

# OUT: 1 flag: whether integrity is ok

sub integrityok { shift->integrity !~ m#\berror#si } #integrityok

#------------------------------------------------------------------------

#  IN: 1 new logfile specification
# OUT: 1 old/current logfile specification

sub log { shift->_class_variable( 'log',@_ ) } #log

#------------------------------------------------------------------------

# OUT: 1 MD5 signature of the XML

sub md5 {

# Return now if we attempted to do an MD5 and no support was found before

  return if defined( $makemd5 ) and !ref($makemd5);

# If we didn't try to load support before
#  Check if we can load the support
#  Return now if failed, setting flag on the fly
#  Set the reference to the routine needed
# Return the signature of the XML

  unless (defined( $makemd5 )) {
    eval( 'use Digest::MD5 ()' );
    return $makemd5 = '' if !defined( $Digest::MD5::VERSION );
    $makemd5 = \&Digest::MD5::md5_hex;
  }
  return &{$makemd5}( shift->write_string );
} #md5

#------------------------------------------------------------------------

# OUT: 1 information added to log file since last call

sub result {

# Obtain the object

  my $self = shift;

# Obtain the name of the log file
# Attempt to open the log file for reading
# Return now if failed

  my $log = $self->log;
  my $handle = $self->openfile( $log );
  return unless $handle;

# Set the field name for the position to read from
# Make sure we start there

  my $field = ref($self).'::READFROM';
  seek( $handle,$self->{$field} || 0,0 );

# Obtain the result
# Keep current position to read from next time
# Close the handle

  my $result = join( '',<$handle> );
  $self->{$field} = tell( $handle );
  close( $handle );

# Return the final result

  return $result;
} #result

#------------------------------------------------------------------------

#  IN: 1 filename of file to be read
# OUT: 1 calling object

sub read_file {

# Obtain the object
# Obtain the filename to work with

  my $self = shift;
  my $filename = shift || $self->filename;

# If opening of the file was succcessful
#  Save the filename
#  Return whatever is the result of reading the handle
# Add error and return object

  if (my $handle = $self->openfile( $filename )) {
    $self->{ref($self).'::filename'} = $filename;
    return $self->read_fh( $handle );
  }
  return $self->_add_error( "Could not open file '$filename': $!" );
} #read_file

#------------------------------------------------------------------------

#  IN: 1 handle of file to be read
# OUT: 1 calling object

sub read_fh {

# Obtain the object
# Obtain the class of the object
# Obtain the handle to work with

  my $self = shift;
  my $class = ref($self);
  my $handle = shift;

# Enable slurp mode
# Read the XML from the file and close it
# Parse the XML
# Set the flag for file ok if there is a version now
# Return the object itself

  local $/ = undef;
  my $xml = <$handle>; close( $handle );
  $self->read_string( $xml );
  $self->{$class.'::FILEOK'} = exists( $self->{$class.'::version'} );
  return $self;
} #read_fh

#------------------------------------------------------------------------

#  IN: 1 XML to be stored
# OUT: 1 calling object

sub read_string {

# Obtain the object
# Obtain the XML to work with
# Remove any internal representation
# Return the original object

  my $self = shift;
  $self->{ref($self).'::xml'} = shift;
  $self->_delete_dom;
  return $self;
} #read_string

#------------------------------------------------------------------------

#  IN: 1 filename of file to write to (default: started with)
# OUT: 1 calling object

sub write_file {

# Obtain the object
# Obtain the class
# Obtain the filename to work with

  my $self = shift;
  my $class = ref($self);
  my $filename = shift || $self->{$class.'::filename'};
  return $self->_add_error( "No filename specified" ) unless $filename;

# If opening of the file was succcessful
#  Save the filename
#  Return whatever is the result of reading the handle
# Add error and return object

  if (my $handle = $self->openfile( $filename,'>' )) {
    $self->{$class.'::filename'} = $filename;
    return $self->write_fh( $handle );
  }
  return $self->_add_error( "Could not write to file '$filename': $!" );
} #read_file

#------------------------------------------------------------------------

#  IN: 1 handle of file to write to
# OUT: 1 calling object

sub write_fh {

# Obtain the object
# Obtain the handle to work with

  my $self = shift;
  my $handle = shift;

# Write the XML to the file, save whether successful
# Close the handle
# Return the object itself

  $self->{ref($self).'::FILEOK'} = print $handle $self->write_string;
  close( $handle );
  $self;
} #write_fh

#------------------------------------------------------------------------

# OUT: 1 serialized XML of the object

sub write_string {

# Obtain the object
# Return what we have already or create the XML out of the DOM

  my $self = shift;
  return $self->{ref($self).'::xml'} ||= $self->_create_xml;
} #write_string

#-------------------------------------------------------------------------

#  IN: 1 new XML
# OUT: 1 old/current XML

sub xml {

# Obtain the object
# Obtain the XML if not called in a void context
# Create new XML if specified
# Return whatever the XML was

  my $self = shift;
  my $xml = $self->write_string if defined(wantarray);
  $self->read_string( shift ) if $_[0];
  return $xml;
} #xml

#-------------------------------------------------------------------------

# Following subroutines are for internal use only

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 reference to hash with method/value pairs
# OUT: 1 instantiated NexTrieve::xxxxx object

sub _new {

# Obtain the class we need to bless
# Create an empty object
# Bless the object

  my $class = shift;
  my $self = {};
  bless $self,$class;

# Make sure we have a copy of the reference to the NexTrieve object
# Inherit anything that needs to be inherited
# Set any fields that are specified

  $self->{'Nextrieve'} = shift;
  $self->_inherit;
  $self->Set( shift ) if $_[0];

# Return the object

  return $self;
} #_new

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 filename/xml (if any)
# OUT: 1 instantiated NexTrieve::xxxxx object

sub _new_from_filename_xml {

# Create the object
# Handle the filename or the XML if there is any
# Return the created object

  my $self = shift->_new( shift );
  $self->_filename_xml( shift ) if $_[0];
  return $self;
} #_new_from_filename_xml

#-------------------------------------------------------------------------

#  IN: 1 filename or xml specification

sub _filename_xml {

# Obtain the object
# Obtain the filename or XML

  my $self = shift;
  my $filename = shift;

# If there is a filename
#  If it is a hash reference
#   Assume we're setting multiple values
#  Elseif there is no newline and it is a file that exists
#   Read that file
#  Else (assume it is a string)
#   Read it as XML

  if ($filename) {
    if (ref($filename) =~ m#^(?:ARRAY|HASH)$#) {
      $self->Set( $filename );
    } elsif ($filename !~ m#\n#s and -s $filename) {
      $self->read_file( $filename );
    } else {
      $self->read_string( $filename );
    }
  }

# Return the object

  return $self;
} #_filename_xml

#-------------------------------------------------------------------------

#  IN: 1 object to inherit from (default: parent NexTrieve object)
# OUT: 1 object itself

sub _inherit {

# Obtain the object
# Obtain the class of the object
# Create local copy of original NexTrieve object

  my $self = shift;
  my $nextrieve = shift || $self->{'Nextrieve'};

# For names of all of the fields that we need to copy
#  Copy the value

  foreach (qw(
   DieOnError
   NexTrievePath
   NexTrieveVersion
   ShowErrorsAsWarnings
   Tmp
    )) {
    $self->{$_} ||= $nextrieve->{$_} if exists $nextrieve->{$_};
  }
  return $self;
} #_inherit

#-------------------------------------------------------------------------

#  IN: 1 error message to add
# OUT: 1 object itself (for handy oneliners)

sub _add_error {

# Obtain the object
# Save whatever was specified as an error

  my $self = shift;
  my $message = shift;

# If we're to die on errors
#  If it is a code reference
#   Execute it, passing the message as a parameter
#  Else
#   Eval what we had as a value
#  Die now if we hadn't died already
  
  if (my $die = $self->{'DieOnError'} || '') {
    if (ref($die) eq 'CODE') {
      &{$die}( $message );
    } else {
      eval( $die );
    }
    die "$message\n";
  }

# Show error as warning if we should
# Save the error on the list
# Return the object again

  warn "$message\n" if $self->{'ShowErrorsAsWarnings'};
  push( @{$self->{ref($self).'::Errors'}},$message );
  return $self;
} #_add_error

#------------------------------------------------------------------------

#  IN: 1 filename of program
#      2 verbose flag
# OUT: 1 command to execute (none: error)
#      2 logfile to save result to
#      3 index directory (where pid file can be located)
# sets indexdir and log if not set already
# writes resource file if not already written

sub _command_log {

# Obtain the object
# Obtain the filename
# Set the verbose string
# Obtain the path where NexTrieve is located
# Create the initial program name

  my $self = shift;
  my $filename = shift;
  my $verbose = scalar(shift) ? ' -v' : '';
  my $path = $self->NexTrievePath;
  my $command = "$path/$filename";

# If the binary does not exist
#  Add error to object and return

  unless (-e $command) {
    $self->_add_error( "Cannot find $command" );
    return;
  }

# If the binary is not executable by this user
#  Add error to object and return

  unless (-x $command) {
    $self->_add_error( "Cannot execute $command" );
    return;
  }

# Obtain local copy of the Resource
# If there is no resource yet
#  Add error to object and return

  my $resource = $self->Resource;
  unless ($resource) {
    $self->_add_error( "Must have a resource specification" );
    return;
  }

# Obtain the objects own indexdir
# Obtain the indexdir from the resource if there is none yet
# If we don't have an indexdir still
#  Add error to object and return

  my $indexdir = $self->indexdir || '';
  $self->indexdir( $indexdir = $resource->indexdir || '' ) unless $indexdir;
  unless ($indexdir) {
    $self->_add_error( "Must have an indexdir specification" );
    return;
  }

# Obtain the filename of the resource file
# If there is none
#  Create a standard filename in the indexdir
#  Write the resource file there
# Elseif the file was not written yet
#  Write the resource file to whatever it was specified

  my $resourcefile = $resource->filename || '';
  unless ($resourcefile) {
    $resourcefile = $resource->filename( "$indexdir/resource.xml" );
    $resource->write_file;
  } elsif( !$resource->{'NexTrieve::Resource::FILEOK'} ) {
    $resource->write_file;
  }

# If there still isn't a resource file
#  Add error to object and return

  unless (-e $resourcefile) {
    $self->_add_error( "Resource '$resourcefile' must exist" );
    return;
  }

# Create the final command
# Return now if we don't want the log file name

  $command = "$command$verbose -R $resourcefile -I $indexdir";
  return $command unless wantarray;

# Obtain the log name
# Set the log filename if not set already
# Save the position to read the result from
# Return the command and the log name

  my $log = $self->log || '';
  $self->log( $log = "$indexdir/$filename.log" ) unless $log;
  $self->{ref($self).'::READFROM'} = -e $log ? -s _ : 0;
  return ($command,$log,$indexdir);
} #_command_log

#-------------------------------------------------------------------------

#  IN: 1 server:port or port specification
# OUT: 1 socket (undef if error)

sub _socket {

# Obtain the object
# Obtain the server:port specification
# Set the default host if only a port number specified

  my $self = shift;
  my $serverport = shift;
  $serverport = "localhost:$serverport" if $serverport =~ m#^\d+$#;

# Attempt to open a socket there
# Set error if failed
# Return whatever we got

  my $socket = IO::Socket::INET->new( $serverport );
  $self->_add_error( "Error connecting to $serverport: $@" )
   unless $socket;
  return $socket;
} #_socket

#-------------------------------------------------------------------------

# The following methods are for setting and obtaining values from the dom

#-------------------------------------------------------------------------

#  IN: 1 name of field in hash, without class prefix
#      2 new value (default: no change)
# OUT: 1 current/old value

sub _class_variable {

# Call the base variable option, prefixing the class name

  return _variable( $_[0],ref(shift).'::'.shift,@_ );

} #_class_variable

#-------------------------------------------------------------------------

#  IN: 1 name of field in hash, without class prefix
#      2 new value (default: no change)
# OUT: 1 current/old value

sub _class_variable_kill_xml {

# Obtain the object
# If there are changes to be made
#  Kill any XML
# Else (no changes are to be made)
#  Make sure that we have a DOM

  my $self = shift;
  if (@_ > 1) {
    $self->_kill_xml;
  } else {
    $self->_create_dom;
  }

# Call the base variable option, prefixing the class name

  return _variable( $self,ref($self).'::'.shift,@_ );
} #_class_variable_kill_xml

#-------------------------------------------------------------------------

#  IN: 1 name of field in hash
#      2 new value (default: no change)
# OUT: 1 current/old value

sub _variable {

# Obtain the object
# Obtain the name of the field
# Obtain its current value

  my $self = shift;
  my $name = shift;
  my $value = $self->{$name};

# Set the new value if there is a new value specified
# Return the current/old value

  $self->{$name} = shift if defined($_[0]);
  return $value;
} #_variable

#-------------------------------------------------------------------------

#  IN: 1 name of field in hash
#      2 new value (default: no change)
# OUT: 1 current/old value

sub _variable_kill_xml {

# If a new value is going to be set
#  Make sure the XML dies
# Else
#  Make sure we have a DOM
# Handle the rest as normal

  if (@_ > 2) {
    $_[0]->_kill_xml;
  } else {
    $_[0]->_create_dom;
  }
  goto &_variable;
} #_variable_kill_xml

#-------------------------------------------------------------------------

#  IN: 1 field name of hash object
#      2 field name
#      3 new value (default: no change)
# OUT: 1 current/old value

sub _field_variable_kill_xml {

# Obtain the object
# If there are going to be changes made
#  Kill any XML
# Else (no changes)
#  Make sure that we have a DOM

  my $self = shift;
  if (@_ > 2) {
    $self->_kill_xml;
  } else {
    $self->_create_dom;
  }

# Call the base variable option for this field

  return _variable( $self->{shift},@_ );
} #_field_variable_kill_xml

#-------------------------------------------------------------------------

#  IN: 1 name of field
#      2 name of subfield
#      3 reference to list of keys in hash
#      4..N new values (default: no change)
# OUT: 1..N current/old values (returns only 1 in scalar context)

sub _field_variable_hash {

# Obtain the object
# Obtain the reference to the hash, or create new one and save at the same time
# Obtain the names of the field

  my $self = shift;
  my $hash = $self->{scalar(shift)}->{scalar(shift)} ||= {};
  my @name = @{scalar(shift)};

# Initialize the current/old values list
# For all of the names specified
#  Save current value
#  Set value if there is a value
# Return the old/current values

  my @value;
  foreach (@name) {
    push( @value,$hash->{$_} );
    $hash->{$_} = shift if $_[0];
  }
  return wantarray ? @value : $value[0];
} #_field_variable_hash

#-------------------------------------------------------------------------

#  IN: 1 name of field
#      2 name of subfield
#      3 reference to list of keys in hash
#      4..N new values (default: no change)
# OUT: 1..N current/old values

sub _field_variable_hash_kill_xml {

# Obtain the object
# If there are new values to be set
#  Kill any XML
# Else (we're not setting new values in the dom)
#  Create a dom (if there isn't one already of course)

  my $self = shift;
  if (@_ > 3) {
    $self->_kill_xml;
  } else {
    $self->_create_dom;
  }

# Perform the rest as a normal event

  return _field_variable_hash( $self,@_ );
} #_field_variable_hash_kill_xml

#------------------------------------------------------------------------

#  IN: 1 field name
#      2 reference to list with allowable fieldnames
#      3..N all variables (name or list, hash ref)
# OUT: 1..N list of all variables, each element list ref [name,@fieldname]

sub _all_field_variable_hash_kill_xml {

# Obtain the object
# Obtain the name of the field to work with
# Obtain local copy of keys to work with
# Also create a local hash with ordinal numbers in them

  my $self = shift;
  my $field = shift;
  my @key = @{scalar(shift)};
  my %key = map {($key[$_],$_+1)} 0..$#key;

# Initialize the list of old values
# If we're expected to return something
#  For all of the attributes specified
#   Save the current values

  my @old;
  if (defined(wantarray)) {
    foreach my $name (keys %{$self->{$field}}) {
      push( @old,[$name,@{$self->{$field}->{$name}}{@key}] );
    }
  }

# If we should set the new set of attributes
#  Initialize the new hash with attributes
#  Initialize the reference to the hash with the previous values

  if (@_ or (!@_ and !defined(wantarray))) {
    my $new = {};
    my $previous = {map {($_,'')} @key};

#  While there are parameters to be processed
#   Initialize the name for this attribute
#   Initialize the hash for this attribute
#   For all of the possible fields
#    Copy the value from the previously specified one

    while (my $ref = shift) {
      my $name;
      my %this;
      foreach (@key) {
        $this{$_} = $previous->{$_};
      }

#   If we were given a list to work with
#    Obtain the name
#    For all of the possible fields
#     Set the value if one is specified

      if (ref($ref) eq 'ARRAY') {
        $name = $ref->[0];
        foreach (@key) {
          $this{$_} = $ref->[$key{$_}] if defined( $ref->[$key{$_}] );
        }

#   Elseif we were given a hash
#    Obtain the name
#    For all of the possible keys
#     Obtain the value if there is one
 
      } elsif (ref($ref) eq 'HASH') {
        $name = $ref->{'name'};
        foreach (@key) {
          $this{$_} = $ref->{$_} if exists $ref->{$_};
        }

#   Else (just a name)
#    Copy the name, the rest of the parameters are already set now
#   Save the new setting in the hash, remember for the next iteration

      } else {
        $name = $ref;
      }
      $previous = $new->{$name} = \%this;
    }

#  Make sure there is no XML for this object anymore
#  Set the finalized new hash in the object

    $self->_kill_xml;
    $self->{$field} = $new;
  }

# Return whatever the old state was

  return @old;
} #_all_field_variable_hash_kill_xml

#------------------------------------------------------------------------

#  IN: 1 base field postfix
#      2 name of field
#      3 new value
# OUT: 1 current/old value

sub _single_value {

# Obtain the object

  my $self = shift;

# If there are changes to be made
#  Make sure we lose the XML
# Else
#  Make sure we have a DOM

  if (@_ > 2) {
    $self->_kill_xml;
  } else {
    $self->_create_dom;
  }

# Return the specified value from the hash, making sure the field exists

  return _variable( $self->{ref($self).'::'.shift} ||= {},@_ );
} #_single_value

#------------------------------------------------------------------------

#  IN: 1 base field postfix
#      2 name of field
# OUT: 1 value found

sub _single_value_ro {

# Obtain the object
# Obtain the class

  my $self = shift;
  my $class = ref($self);

# Make sure we have a DOM
# Return the specified value from the hash

  $self->_create_dom;
  return $self->{$class.'::'.shift}->{scalar(shift)};
} #_single_value_ro

#------------------------------------------------------------------------

#  IN: 1 base field postfix
#      2 name of field
# OUT: 1..N values found (returns first in scalar context)

sub _multi_value_ro {

# Obtain the object
# Obtain the class

  my $self = shift;
  my $class = ref($self);

# Make sure we have a DOM
# Return the specified value from the hash or just the first

  $self->_create_dom;
  return wantarray ?
         map {$_->[1]} @{$self->{$class.'::'.shift}->{scalar(shift)}} :
         $self->{$class.'::'.shift}->{scalar(shift)}->[0]->[1];
} #_multi_value_ro

#-------------------------------------------------------------------------

sub _kill_xml {

# Obtain the object
# Set the field name for the XML

  my $self = shift;
  my $xml = ref($self).'::xml';

# Create the dom for this object (in case there is none yet)
# Remove the ready XML if there is any

  $self->_create_dom;
  delete( $self->{$xml} ) if exists $self->{$xml};
} #_kill_xml

#-------------------------------------------------------------------------

# The following methods are for converting XML to dom and vice-versa

#-------------------------------------------------------------------------

#  IN: 1 reference to XML to work with
# OUT: 1 encoding found

sub _encoding_from_xml {

# Obtain the object
# Obtain the XML to work with

  my $self = shift;
  my $xml = shift;

# Attempt to remove the xml processor instruction
# Find the attributes of the processor instruction
# Return whatever was found

  $$xml =~ s#^<\?xml(.*?)\?>##s;
  my $pi = $self->_attributes2hash( $1 );
  return $pi->{'encoding'} || '';
} #_encoding_from_xml

#-------------------------------------------------------------------------

#  IN: 1 reference to XML to work with
#      2 outer container name to look for
# OUT: 1 encoding found
#      2 any additional attributes found (optional)

sub _version_from_xml {

# Obtain the object
# Obtain the XML to work with
# Obtain the container name
# Initialize the version
# Initialize the attributes

  my $self = shift;
  my $xml = shift;
  my $container = shift;
  my $version = '';
  my $attributes ='';

# If the container is there
#  Save the version information
# Else 
#  Set error message

  if ($$xml =~ s#<$container\s+(.*?)xmlns:ntv="http://www.nextrieve.com/([^"]+)(.*?")\s*>\s*(.*)</$container>#$4#s) {
    $version = $2;
    $attributes = $1.$3;
  } else {
    $self->_add_error( "Cannot find the <$container> container" );
  }

# Return whatever was found

  return wantarray ? ($version,$attributes) : $version;
} #_version_from_xml

#-------------------------------------------------------------------------

# OUT: 1 version found
#      2 initial XML with processing instruction (empty if no encoding found)

sub _init_xml {

# Obtain the object
# Obtain its class

  my $self = shift;
  my $class = ref($self);

# Obtain the version
# If there is version information
#  If it is not a supported version
#   Add error and return

  my $version = $self->{$class.'::version'} || '';
  if ($version) {
    if ($version !~ m#^(?:1.0)$#) {
      $self->_add_error( "'$version' is not supported by this version of '$class'" );
      return;
    }

# Else (no version information)
#  Add error and return

  } else {
    $self->_add_error( "Cannot create XML without version information" );
    return;
  }

# Initialize the XML
# Obtain the encoding
# Add encoding if there is any

  my $xml = '';
  my $encoding =
   $self->{$class.'::encoding'} || $self->NexTrieve->encoding || '';
  $xml .= <<EOD if $encoding;
<?xml version="1.0" encoding="$encoding"?>
EOD

# Return the version and XML

  return ($version,$xml);
}

#-------------------------------------------------------------------------

#  IN: 1 name of container
#      2 attributes to be added (should start with space)
# OUT: 1 XML (or undef in case of error)

sub _init_container {

# Obtain the object
# Obtain its class
# Obtain the container
# Obtain the attributes

  my $self = shift;
  my $class = ref($self);
  my $container = shift;
  my $attributes = shift || '';

# Return the XML

  return <<EOD;
<ntv:$container xmlns:ntv="http://www.nextrieve.com/$self->{$class.'::version'}"$attributes>
EOD
}

#-------------------------------------------------------------------------

#  IN: 1 xml to scan, is changed directly so must be a left value
# OUT: 1 reference to hash of a list of a list of hash refs

sub _containers2hash {

# Obtain the object

  my $self = shift;

# Initialize the hash
# For all of the filled containers
#  Save the list ref for the attributes and the contents in the hash
# Return the reference to the hash

  my %hash;
  while ($_[0] =~ s#<([\w\-\_]+)\s*(.*?)(?:/|>(.*?)</\1)>##s) {
    push( @{$hash{$1}},[$self->_attributes2hash( $2 ),$3] );
  }
  return \%hash;
} #_containers2hash

#-------------------------------------------------------------------------

#  IN: 1 reference to hash of list of hash refs
#      2 reference to list of names of containers (default: all)
# OUT: 1 xml to scan

sub _hash2containers {

# Obtain the object
# Obtain the hash reference

  my $self = shift;
  my $hash = shift;

# Initialize the XML
# For all of the keys that need to be done
#  For all of the containers with the same name in there

  my $xml;
  foreach my $name (@_ ? @{$_[0]} : keys %{$hash}) {
    foreach my $container (@{$hash->{$name}}) {

#   If there is a filling to this container
#    Add the XML for that
#   Else (an empty container)
#    Add the XML for an empty container

      if ($container->[1]) {
        $xml .= "<$name".$self->_hash2attributes( $container->[0] ).">$container->[1]</$name>\n";
      } else {
        $xml .= "<$name".$self->_hash2attributes( $container->[0] )."/>\n";
      }
    }
  }

# Return the xML

  return $xml;
} #_hash2containers

#-------------------------------------------------------------------------

#  IN: 1 xml to scan
#      2 name of container (take name attribute as key)
# OUT: 1 reference to hash of hash refs
#      2 remaining XML (optional)

sub _emptycontainers2namehash {

# Obtain the object
# Obtain the XML

  my $self = shift;
  my $xml = shift || '';
  my $container = shift || '';

# Initialize the hash
# If there is something to do
#  For all of the empty containers
#   Save the hash ref for the attributes in the hash
# Return a reference to the hash

  my %hash;
  if ($xml) {
    while ($xml =~ s#<$container\s+(.*?)(?:/|></\1)>##s) {
      my $attributes = $1;
      my $name = $1 if $attributes =~ s#name="([^"]+)"\s*##s;
      $hash{$name} = $self->_attributes2hash( $attributes );
    }
  }
  return wantarray ? (\%hash,$xml) : \%hash;
} #_emptycontainers2namehash

#-------------------------------------------------------------------------

#  IN: 1 reference to hash of hash references
#      2 name of container to create
#      3 reference to list of names of attributes to set (default: all)
# OUT: 1 xml created

sub _namehash2emptycontainers {

# Obtain the object
# Obtain the hash to process
# Obtain the name of the container
# Obtain the list of attribute names to process

  my $self = shift;
  my $hash = shift;
  my $container = shift;
  my $list = shift;

# Initialize the XML
# For all of the elements in the list
#  Add container to the XML
# Return the final XML

  my $xml;
  foreach (keys %{$hash}) {
    $xml .= qq(<$container name="$_").$self->_hash2attributes($hash->{$_},$list )."/>\n";
  }
  return $xml;
} #_namehash2emptycontainers

#-------------------------------------------------------------------------

#  IN: 1 xml to scan
# OUT: 1 reference to hash of hash refs

sub _emptycontainers2hash {

# Obtain the object
# Obtain the XML

  my $self = shift;
  my $xml = shift || '';

# Initialize the hash
# If there is something to do
#  For all of the empty containers
#   Save the hash ref for the attributes in the hash
# Return a reference to the hash

  my %hash;
  if ($xml) {
    while ($xml =~ s#<([\w\-\_]+)\s+(.*?)(?:/|></\1)>##s) {
      $hash{$1} = $self->_attributes2hash( $2 );
    }
  }
  return \%hash;
} #_emptycontainers2hash

#-------------------------------------------------------------------------

#  IN: 1 reference to hash of hash references
#      2 reference to list of names of attributes to set (default: all)
# OUT: 1 xml created

sub _hash2emptycontainers {

# Obtain the object
# Obtain the hash to process
# Obtain the list of attribute names to process

  my $self = shift;
  my $hash = shift;
  my $list = shift || '';

# Initialize the XML
# For all of the elements in the list
#  Obtain the attributes
#  Add container to the XML if there are attributes
# Return the final XML

  my $xml;
  foreach (keys %{$hash}) {
    my $attributes = $self->_hash2attributes($hash->{$_},$list ) || '';
    $xml .= "<$_$attributes/>\n" if $attributes;
  }
  return $xml;
} #_hash2emptycontainers

#-------------------------------------------------------------------------

#  IN: 1 xml to scan
# OUT: 1 reference to list of hash refs

sub _emptycontainers2list {

# Obtain the object
# Obtain the XML
# Obtain the name of the container

  my $self = shift;
  my $xml = shift;
  my $name = shift;

# Initialize the list of containers
# For all of the empty containers with the name
#  Add a hash ref to its attributes and values
# Return reference to the final list

  my @list;
  while ($xml =~ s#<$name\s+(.*?)/>##s) {
    push( @list,$self->_attributes2hash( $1 ) );
  }
  return \@list;
} #_emptycontainers2list

#-------------------------------------------------------------------------

#  IN: 1 reference to list of hash references
#      2 name of the empty containers to create
#      3 reference to list names of attributes to set (default: all attributes)
# OUT: 1 xml created

sub _list2emptycontainers {

# Obtain the object
# Obtain the list
# Obtain the name of the container

  my $self = shift;
  my $name = shift;
  my $list = shift || '';

# Initialize the XML
# For all of the elements in the list
#  Add container to the XML
# Return the final XML

  my $xml;
  foreach (@{$list}) {
    $xml .= "<$name".$self->_hash2attributes($_,@_ )."/>\n";
  }
  return $xml;
} #_list2emptycontainers

#-------------------------------------------------------------------------

#  IN: 1 xml to scan
#      2 reference to list of expected keys
# OUT: 1 reference to hash with hash refs

sub _attributes2hash {

# Obtain the object
# Obtain the attributes text
# Initialize the hash, fill with empty values that are expected if specified

  my $self = shift;
  my $attributes = shift;
  my %hash; %hash = map {($_,'')} @{scalar(shift)} if $_[0];

# If there are attributes
#  If there are expected values
#   While there are attributes
#    Save the attribute in the hash if it was expected
#  Else (no expected values)
#   While there are attributes
#    Save the attribute in the hash (always)

  if ($attributes) {
    if (keys %hash) {
      while ($attributes =~ s#([\w\-\_]+)\s*=\s*"([^"]+)"##s) {
        $hash{$1} = $2 if exists $hash{$1};
      }
    } else {
      while ($attributes =~ s#([\w\-\_]+)\s*=\s*"([^"]+)"##s) {
        $hash{$1} = $2;
      }
    }
  }

# Return a reference to the hash

  return \%hash;
} #_attributes2hash

#-------------------------------------------------------------------------

#  IN: 1 hash reference
#      2 reference to list names of keys to use (default: all keys in hash)
# OUT: 1 xml

sub _hash2attributes {

# Obtain the object
# Obtain the hash
# Obtain the list

  my $self = shift;
  my $hash = shift;
  my $list = shift || '';

# Initialize the XML
# For all of the keys in the hash that we need to process
#  Add to the XML if there is something to add
# Return the final result, always starts with a space

  my $xml = '';
  foreach ($list ? @{$list} : keys %{$hash}) {
    $xml .= qq( $_="$hash->{$_}") if $hash->{$_};
  }
  return $xml;
} #_hash2attributes

#------------------------------------------------------------------------

# Internal subroutines, in case there is no local copy

#------------------------------------------------------------------------

sub _create_dom {} #_create_dom

#------------------------------------------------------------------------

sub _delete_dom {} #_delete_dom

#-------------------------------------------------------------------------

# subroutines for standard Perl features

#-------------------------------------------------------------------------

#  IN: 1..N submodules to include (default = all)

sub import {

# Obtain the class
# Return now if called through one of the submodules

  my $class = shift;
  return unless $class eq 'NexTrieve';

# Initialize the list of -use-d submodules
# Initialize the complete list of submodules
# Join them together for matching

  my @use;
  my @all = qw(
   Collection
   Daemon
   Docseq
   Document
   Hitlist
   Hitlist::Hit
   Index
   Query
   Querylog
   Replay
   Resource
   Search
  );
  my $all = join( '|',@all );

# If there was something specified
#  For all of the parameters
#   If it is indicated to get all
#    Set that list

  if (@_) {
    foreach (@_) {
      if ($_ eq ':all') {
        @use = @all;

#   Elseif it is a known submodule
#    Add it to the list
#   Else (don't know what to do with it)
#    Warn the user

      } elsif (m#^(?:$all)$#o) {
        push( @use,$_ );
      } else {
        warn "Don't know how to import $_\n";
      }
    }

# Else (no parameters specified)
#  Set to do all

  } else {
    @use = @all;
  }

# For all of the submodules to be used
#  Make sure that the submodule is available

  foreach (@use) {
    eval "use NexTrieve::$_;";
  }
} #import

#-------------------------------------------------------------------------

# Debugging tools

#-------------------------------------------------------------------------

#  IN: 1..N variables to be dumped also, apart from object itself
# OUT: 1 Dumper output (if Data::Dumper available)

sub Dump {

# Obtain the object
# Attempt to get the Data::Dumper module
# If the module is available
#  Return the result of the dump if we're expecting something
#  Output the result the dump as a warning (in void context)

  my $self = shift;
  eval 'use Data::Dumper ();';
  if (defined( $Data::Dumper::VERSION )) {
    return Data::Dumper->Dump( [$self,@_] ) if defined( wantarray );
    warn Data::Dumper->Dump( [$self,@_] );
  }
}

#-------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve - Perl interface to NexTrieve search engine software

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = new NexTrieve( | {method => value} );

 # doing everything in Perl
 $search = $ntv->Search( host:port | port | resourcefile | $resource );
 $hitlist = $search->Hitlist( $query | queryfile | xml | {method => value} );
 foreach $hit ($hitlist->Hits) {
 # display result here
 }

 # if you want to process your own XML
 $hitlistxml = $ntv->ask_server_port( server:port | port,$queryxml );

=head1 DESCRIPTION

Provide a Perl interface to the complete functionality of NexTrieve.

Almost all aspects of NexTrieve are handled through XML.  If you are not well
versed in the handling of XML, and you B<are> well versed in using Perl, then
these Perl modules are for you: they will handle everything in a completely
object-oriented manner.

The following modules are part of the basic distribution:

 NexTrieve			base module
 NexTrieve::Collection		logical collection object	
 NexTrieve::Daemon		logical daemon object
 NexTrieve::Docseq		logical document sequence for indexing
 NexTrieve::Document		logical document object
 NexTrieve::Resource		create/adapt resource-file
 NexTrieve::Index		index XML
 NexTrieve::Replay		turn Querylog into Hitlist objects for a Search
 NexTrieve::Search		logical search engine object
 NexTrieve::Query		create/adapt query
 NexTrieve::Querylog		turn query log into Query objects
 NexTrieve::Hitlist		result of query from search engine
 NexTrieve::Hitlist::Hit	a single hit of the result

If you are used to handling XML in Perl, you probably only need the IO::Socket
module to perform searches with NexTrieve.  Or you can use the method
L<ask_server_port>, which provides a shortcut for that.

=head1 SELECTIVE SUBMODULE LOADING

Not all of the NexTrieve submodules may be needed in a particular situation.
In order to save CPU and memory, you can easily load only the necessary
submodules, by specifying their names in the -use- statement with which
you load this module. E.g.,

 use NexTrieve;    or    use NexTrieve qw(:all);

will load B<all> submodules of NexTrieve (which may become more over the course
of time).  If you would only like to use the NexTrieve::Query submodule, you
can specify this as:

 use NexTrieve qw(Query Hitlist);

This can e.g. be handy if you only want to use the Query and Hitlist features.

=head1 SETUP METHODS

The following methods are available for setting up the NexTrieve object itself.

=head2 ask_server_port

 $hitlistxml = $ntv->ask_server_port( server:port | port,$queryxml );

=head1 INHERITED METHODS

The following methods are inherited from the NexTrieve object whenever any of
the sub-objects are made.  This means that any setting in the NexTrieve object
of these methods, will automatically be activated in the sub-objects in the
same manner.

=head2 DieOnError

 $DieOnError = $ntvobject->DieOnError;
 $ntvobject->DieOnError( true | false );

=head2 NexTrievePath

 $NexTrievePath = $ntv->NexTrievePath;
 $ntv->NexTrievePath( '/usr/local/nextrieve/bin' ); # checks NTV_PATH=

=head2 NexTrieveVersion

 $NexTrieveVersion = $ntv->NexTrieveVersion;
 $ntv->NexTrieveVersion( '2.0.0' ); # short for /usr/local/nextrieve/2.0.0

=head2 ShowErrorsAsWarnings

 $ShowErrorsAsWarnings = $ntvobject->ShowErrorsAsWarnings;
 $ntvobject->ShowErrorsAsWarnings( true | false );

=head2 Tmp

 $Tmp = $ntv->Tmp;
 $ntv->Tmp( '/tmp' ); # checks TMP=

=head1 CONVENIENCE METHODS

The following methods are inheritable from the NexTrieve module.  They are
intended to make life easier for the developer, and are specifically intended
to be used within user scripts such as templates.

=head2 Set

 $ntvobject->Set( {
  methodname1	=> $value1,
  methodname2	=> $value2,
  methodname2	=> [parameter1,parameter2],
 } );

=head2 Get

 ($var1,$var2) = $ntvobject->Get( qw(methodname1 methodname2) );
 $ntvobject->Get( qw(methodname1 methodname2) ); # sets global vars

=head2 Errors

 @error = $ntvobject->Errors;

=head1 XML METHODS

The following methods have to do with all of the objects that are directly
related to the XML representation used by NexTrieve.  They are inherited from
the NexTrieve module by NexTrieve::Resource, NexTrieve::Query and
NexTrieve::Hitlist.

=head2 filename

 $filename = $ntvobject->filename;
 $ntvobject->filename( filename );

=head2 encoding

 $encoding = $ntvobject->encoding;
 $ntvobject->encoding( $encoding ); # sets default on $ntv

=head2 version

 $version = $ntvobject->version;

=head2 xml

 $xml = $ntvobject->xml;
 $ntvobject->xml( $xml );

=head2 read_file

 $ntvobject->read_file( file );

=head2 read_fh

 open( $handle,file );
 $ntvobject->read_fh( $handle );
 close( $handle );

=head2 read_string

 $ntvobject->read_string( xml );

=head2 write_string

 $xml = $ntvobject->write_string;

=head2 write_fh

 open( $handle,">file" ); 
 $ntvobject->write_fh( $handle );
 close( $handle );

=head2 write_file

 $ntvobject->write_file( | file );

=head1 AUTHOR

Elizabeth Mattijsen, <liz@nextrieve.com>.

Please report bugs to <perlbugs@nextrieve.com>.

=head1 COPYRIGHT

Copyright (c) 1995-2002 Elizabeth Mattijsen <liz@nextrieve.com>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.nextrieve.com and the other NexTrieve::xxx modules.

=cut
