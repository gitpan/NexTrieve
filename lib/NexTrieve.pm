package NexTrieve;

# Set version information
# Make sure we do everything by the book from now on

$VERSION = '0.38';
use strict;

# Use the external modules that we need always

use Date::Parse ();
use IO::File ();
use IO::Socket ();

# Initialize reference to MD5 signature maker if module already loaded

my $makemd5;
$makemd5 = \&Digest::MD5::md5_hex if defined( $Digest::MD5::VERSION );

# Initialize the hash with contentfetchers

my %contentfetcher = (
 ''		=> \&_fetch_direct,
 'filename'	=> \&_fetch_from_filename,
 'url'		=> \&_fetch_from_url,
);

# Initialize the hash with standard processors

my %standardprocessor = (
 datestamp      => \&_datestamp,
 epoch          => \&_epoch,
 timestamp      => \&_timestamp,
);

# Initialize the hash for specific code to code conversions

my %code2code;

# Create the character to entity conversion hash for "ampersandize"
# Create the list of characters for matching for "ampersandize"

my %ampersandize = (
 '&'    => '&amp;',
 '<'    => '&lt;',
 '>'    => '&gt;',
);
my $ampersandize = join( '|',keys %ampersandize );

# Create the character to entity conversion hash for "normalize"
# Create the list of characters for matching for "normalize"

my %normalize = (
 '<'    => '&lt;',
 '>'    => '&gt;',
);
my $normalize = join( '|',keys %normalize );

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

# Satisfy -require-

1;

#-------------------------------------------------------------------------

# Following subroutines are for instantiating objects

#-------------------------------------------------------------------------

#  IN: 1 reference to hash with method value pairs
# OUT: 1 instantiated NexTrieve object

sub new {

# Find out what class we need to be blessing
# If we're not trying to make a NexTrieve object
#  Warn the user it shouldn't be done and return

  my $class = shift;
  if ($class ne 'NexTrieve') {
    warn "Can only call 'new' on NexTrieve itself\n";
    return;
  }

# Create the object
# Bless the object

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
#      2 server:port specification (optional)
#      3 ref to hash with method/value pairs
# OUT: 1 instantiated NexTrieve::Daemon object

sub Daemon { 'NexTrieve::Daemon'->_new( @_ ) } #Daemon

#-------------------------------------------------------------------------

#  IN: 1 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::DBI object

sub DBI { 'NexTrieve::DBI'->_new( @_ ) } #DBI

#-------------------------------------------------------------------------

# As a "class" method
#  IN: 1 ref to method/parameters hash
#      2..N filename/xml specification
# OUT: 1 instantiated NexTrieve::Docseq object

# as an object method
#  IN: 1 Docseq object (optional)
#      2..N list of parameters to be passed to Document method
# OUT: 1 Docseq object

sub Docseq {

# Obtain the object
# Obtain the class of the object
# Initialize the docseq variable

  my $self = shift;
  my $class = ref($self);
  my $docseq;

# If we're doing this as a "class" method from NexTrieve
#  Create a new docseq object from the parameters and return it
# Elseif it is an object method with a Docseq object specification
#  Use that docseq object
# Else (object method without existing Docseq object)
#  Create new docseq object

  if ($class eq 'NexTrieve') {
    return 'NexTrieve::Docseq'->_new_from_filename_xml(
     $self,{encoding => []},@_ );
  } elsif (ref($_[0]) eq 'NexTrieve::Docseq') {
    $docseq = shift;
  } else {
    $docseq = 'NexTrieve::Docseq'->_new_from_filename_xml(
     $self->NexTrieve,{encoding => []} )
  }

# For all of the specified filenames
#  Add the document to the docseq
# Return the docseq object (in case it was new)

  foreach my $parameters (@_) {
    $docseq->add( $self->Document( $parameters ) );
  }
  return $docseq;
} #Docseq

#-------------------------------------------------------------------------

# as a "class" method
#  IN: 1 ref to method/parameters hash
#      2..N filename/xml specification
# OUT: 1 instantiated NexTrieve::Document object

# as an "object" method
#  IN: 1 reference to information hash
#      2 name of key to serve as "id" (default: 'id')
#      3 name of key to serve as default text (default: 'text')
#      4 normalization method (default: 'ampersandize', or 'normalize')
# OUT: 1 instantiated NexTrieve::Document object

sub Document {

# Obtain the object
# Obtain the class of the object
# Return now if called as a class method

  my $self = shift;
  my $class = ref($self);
  return 'NexTrieve::Document'->_new_from_filename_xml( $self,@_ )
   if $class eq 'NexTrieve';

# Create a new Document object with the encoding set

  my $document = $self->NexTrieve->Document( {
   encoding => $self->DefaultInputEncoding
  } );

# Obtain the reference to the content hash
# Obtain the name of the "id" field
# Obtain the name of the "text" field
# Obtain the name of the normalization routine

  my $content = shift;
  my $id = shift || 'id';
  my $text = shift || 'text';
  my $normalize = shift || 'ampersandize';

# Obtain the real id
# If there is an actual text
#  Obtain the text in a variable
#  Make sure it is normalized correctly
#  And delete it from the content hash
# Else (no actual text)
#  Make sure there is none

  $id = $content->{$id} || '';
  if (exists($content->{$text})) {
    $text = $content->{$text} || '';
    $self->$normalize( $text );
    delete( $content->{$text} );
  } else {
    $text = '';
  }

# Create and store the XML
# Return the document

  $self->_hashprocextra( $document,$id,$content,$text,$normalize );
  return $document;
} #Document

#-------------------------------------------------------------------------

#  IN: 1 filename or xml (optional)
# OUT: 1 instantiated NexTrieve::Hitlist object

sub Hitlist { 'NexTrieve::Hitlist'->_new_from_filename_xml( @_ ) } #Hitlist

#-------------------------------------------------------------------------

#  IN: 1 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::HTML object

sub HTML { 'NexTrieve::HTML'->_new( @_ ) } #HTML

#-------------------------------------------------------------------------

#  IN: 1 filename or xml or NexTrieve::Resource object
#      2 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::Index object

sub Index { 'NexTrieve::Index'->_new( @_ ) } #Index

#-------------------------------------------------------------------------

#  IN: 1 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::Mbox object

sub Mbox { 'NexTrieve::Mbox'->_new( @_ ) } #Mbox

#-------------------------------------------------------------------------

#  IN: 1 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::Message object

sub Message { 'NexTrieve::Message'->_new( @_ ) } #Message

#-------------------------------------------------------------------------

# OUT: 1 instantiated NexTrieve object

sub NexTrieve { _variable( shift,'Nextrieve' ) } #NexTrieve

#-------------------------------------------------------------------------

#  IN: 1 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::PDF object

sub PDF { 'NexTrieve::PDF'->_new( @_ ) } #PDF

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
# OUT: 1 instantiated NexTrieve::Replay object

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

  my $self = shift;
  my $class = ref($self);

# If called as a "class" method from NexTrieve
#  Return a new object

  if ($class eq 'NexTrieve') {
    return 'NexTrieve::Resource'->_new_from_filename_xml( $self,@_ );

# Elseif we have a DBI, HTML or RFC822 Resource request
#  Create an empty resource object

  } elsif ($class =~ m#^NexTrieve::(?:DBI|HTML|Message|PDF|RFC822)$#) {
    my $resource = $self->NexTrieve->Resource;

#  For both attributes and texttypes
#   Obtain local copy of extra attribute/texttypes list
#   Obtain local copy of attribute/texttypes hash
#   Set the initial attributes/texttypes

    foreach my $method (qw(attributes texttypes)) {
      my $extra = $self->{$class.'::'.substr($method,0,4).'extra'} || [];
      my $hash = $self->{$class.'::'.substr($method,0,4).'hash'} || {};
      $resource->$method(
       (@{$extra} ? map {[splice(@{$_},1)]} @{$extra} : ()),
       map {@{$hash->{$_}} ? $hash->{$_} : [$_]} keys %{$hash},
      );
    }

#  Set any additional parameters if there are any
#  Return the resource object

    $resource->Set( shift ) if $_[0];
    return $resource;
  }

# Obtain the resource specification
# Obtain the name of the field
# Obtain the current setting

  my $resource = shift;
  my $field = $class.'::Resource';
  my $old = $self->{$field};

# If we have a new specification
#  Obtain the ref type
#  If it is the right object or a server:port specification
#   Save that as resource

  if ($resource) {
    my $objectclass = ref($resource) || '';
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

#  IN: 1 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::RFC822 object

sub RFC822 { 'NexTrieve::RFC822'->_new( @_ ) } #RFC822

#-------------------------------------------------------------------------

#  IN: 1 server:port or filename or xml or NexTrieve::Resource object
# OUT: 1 instantiated NexTrieve::Search object

sub Search { 'NexTrieve::Search'->_new( @_ ) } #Search

#-------------------------------------------------------------------------

#  IN: 1 ref to hash with methods and values
# OUT: 1 instantiated NexTrieve::Message object

sub Targz { 'NexTrieve::Targz'->_new( @_ ) } #Targz

#-------------------------------------------------------------------------

# Following subroutines offer functionality with regards to fields in the object

#-------------------------------------------------------------------------

#  IN: 1 new setting for DefaultInputEncoding (default: no change)
# OUT: 1 current/old setting for DefaultInputEncoding

sub DefaultInputEncoding {

# Obtain the object
# If there is a new encoding, make sure it's normalized and handle it

  my $self = shift;
  _variable( $self,'DefaultInputEncoding',
   @_ ? ($self->_normalize_encoding( shift )) : () ) || 'iso-8859-1';
} #DefaultInputEncoding

#------------------------------------------------------------------------

#  IN: 1 encoding (default: utf8)
# OUT: 1 current encoding (or empty string)

sub encoding {

# Obtain the object
# Create the field name
# Obtain current value of encoding

  my $self = shift;
  my $field = ref($self).'::encoding';
  my $encoding = $self->{$field} || '';

# If there is an encoding specified
#  Obtain the new encoding
#  If there was an encoding already and it's different
#   Obtain current number of errors
#   Obtain the recoded XML
#   If there are still the same number of errors
#    Store the converted XML in the object
#    Set the new encoding

  if (@_) {
    my $new = _normalize_encoding( shift );
    if ($encoding and $new ne $encoding) {
      my $errors = $self->Errors;
      my $xml = $self->recode( $new );
      if ($self->Errors == $errors) {
        $self->read_string( $xml );
        $encoding = $new;
      }

#  Elseif we don't have an encoding yet
#   Just set that encoding

    } elsif (!$encoding) {
      $encoding = $new;
    }
  }

# Return the current encoding, saving it in the object on the fly

  return $self->{$field} = $encoding;
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

  return $self->{'NexTrievePath'} = $path || '';
} #NexTrievePath

#-------------------------------------------------------------------------

#  IN: 1 new version specification
# OUT: 1 current/old version specification

sub NexTrieveVersion {
 _variable( shift,'NexTrieveVersion',@_ ) } #NexTrieveVersion

#-------------------------------------------------------------------------

#  IN: 1 new setting of no-processor instruction flag
# OUT: 1 current/old setting of no-processor instruction flag

sub nopi { shift->_class_variable( 'nopi',@_ ) } #nopi

#-------------------------------------------------------------------------

#  IN: 1 new setting for PrintError (default: no change)
# OUT: 1 current/old setting for PrintError

sub PrintError {

# Obtain the object
# Return now if just returning

  my $self = shift;
  return _variable( $self,'PrintError' ) unless @_;

# Obtain the value
# If it is 'cluck'
#  Load the 'Carp' module
#  Set the reference to the cluck routine if Carp is available
# Handle as normal setting from here on

  my $value = shift;
  if ($value eq 'cluck') {
    eval( 'use Carp ();' );
    $SIG{__WARN__} = \&Carp::cluck if defined(&Carp::cluck);
  }
  return _variable( $self,'PrintError',$value,@_ );
} #PrintError

#-------------------------------------------------------------------------

#  IN: 1 new setting for RaiseError (default: no change)
# OUT: 1 current/old setting for RaiseError

sub RaiseError { 

# Obtain the object
# Return now if just returning

  my $self = shift;
  return _variable( $self,'RaiseError' ) unless @_;

# Obtain the value
# If it is 'confess'
#  Load the 'Carp' module
#  Set the reference to the confess routine if Carp is available
# Handle as normal setting from here on

  my $value = shift;
  if ($value eq 'confess') {
    eval( 'use Carp ();' );
    $SIG{__DIE__} = \&Carp::confess if defined(&Carp::confess);
  }
  return _variable( $self,'RaiseError',$value,@_ );
} #RaiseError

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
    while (my ($method,$parameter) = each %{$ref}) {
      $self->$method( ref($parameter) eq 'ARRAY' ?
       @{$parameter} : $parameter );
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

#-------------------------------------------------------------------------

# IN/OUT: 1..N left-values to normalize

sub ampersandize {

# Get rid of the object if there is one

  shift if ref($_[0]);

# For all of the input parameters
#  Reloop if nothing to do
#  Make sure it is clean

  foreach (@_) {
    next unless $_;
    s#($ampersandize)#$ampersandize{$1}#sgo;	# turn &<> into entities
    s#[\x00-\x08\x0b-\x1f]# #sg;		# remove iso-8859-1 illegals
  }
} #ampersandize

#------------------------------------------------------------------------

#  IN: 1 servername or IP address (defaults to "localhost")
# OUT: 1 random port number

sub anyport {

# Obtain the object
# Initialize the port
# If we can create a socket on a random port
#  Obtain the port (socket will be freed when if goes out of scope)

  my $self = shift;
  my $port = '';
  if (my $socket =
   $self->_socket( [Listen => 5, LocalAddr => (shift || 'localhost')] ) ) {
    $port = $socket->sockport;
  }

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
  return $self->slurp( $socket );
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

#------------------------------------------------------------------------

#  IN: 1 new setting of "binary check" flag
# OUT: 1 current/old setting of "binary check" flag

sub binarycheck { shift->_class_variable( 'binarycheck',@_ ) } #binarycheck

#------------------------------------------------------------------------

#  IN: 1..N new display containers
# OUT: 1..N current/old display containers

sub displaycontainers { shift->_containers( 'display',@_ ) } #displaycontainers

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
    s#($normalize)#$normalize{$1}#sgo;		# turn <> into entities
    s#[\x00-\x08\x0b-\x1f]# #sg;		# remove iso-8859-1 illegals
  }

#  Subroutine for processing the ampersand
#   Obtain the string to check

  sub ampersand {
    my $string = shift;

#   If it was numeric
#    Remember the number
#    Return it if it is a valid code
#    Return special case if it is a TAB

    if (my ($number) = $string =~ m#^\#(\d{1,3})#) {
      return "&#$number;".substr($string,length($number)+1)
       if chr($number) =~ m#^[\x09-\x0a\x20-\x7f\xa0-\xff]$#;
      return '&'.substr($string,0,2).';'.substr($string,2)
       if $string =~ m#^\#9#;

#    Remove the last character from the number
#    While there is someting to be processed
#     Return if what we now have is a legal character
#     Remove the last character

      $number =~ s#.$##;
      while ($number) {
        return "&#$number;".substr($string,length($number)+1)
         if chr($number) =~ m#^[\x09-\x0a\x20-\x7f\xa0-\xff]$#;
        $number =~ s#.$##;
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
# If we can create a handle
#  Make sure we'll always read bytes, specifically in Perl 5.8+
#  Return the handle

  my $self = shift;
  if (my $handle = IO::File->new( @_ )) {
    binmode( $handle );
    return $handle;
  }

# Add error to object
# And return empty handed

  $self->_add_error( "Could not open file '$_[0]': $!" );
  return;
} #openfile

#-------------------------------------------------------------------------

#  IN: 1 encoding or object of which encoding to encode to
#      2 XML to convert (default: write_string of object)
#      3 encoding to convert from (default: object's encoding)
# OUT: 1 XML of object in the given encoding

sub recode {

# Obtain the object
# Obtain the to encoding
# Obtain the xml
# Obtain the from encoding

  my $self = shift;
  my $to = shift;
  my $xml = shift || $self->write_string;
  my $from = _normalize_encoding( shift ) || $self->encoding;

# If we're dealing with intext recoding
#  Convert the text =A9 to &#xA9; (as a character)
#  Use the object's original encoding

  if ($to eq 'intext') {
    $xml =~ s#=([a-fA-F0-9]{2})#pack('C',hex($1))#sge;
    $self->encoding( $to = 'utf-8' ) unless $to = $self->encoding;
  }  

# Normalize the to encoding
# Return the original XML now if they're the same

  $to = ref($to) ? $to->encoding : _normalize_encoding( $to );
  return $xml if $from eq $to;

# If this object does not have an encoding yet
#  Just set the other encoding
#  Return the original XML

  unless ($from) {
    $self->encoding( $to );
    return $xml;
  }

# Initialize the converter
# If an attempt was made previously for this type of conversion
#  Use the result of that attempt

  my $converter;
  if (exists $code2code{$from,$to}) {
    $converter = $code2code{$from,$to};
  }

# If there is still no converter
#  Make sure we have checked whether the Encode module is there
#  If the Encode module is there
#   Create a converter closure
#   Initialize string that can always be converted
#   If it converted successfully
#    Save this converter in the hash
#   Else
#    Reset the converter, we need to try the rest

  if (!$converter) {
    eval( 'use Encode; $Encode::VERSION ||= ""' )
     unless defined( $Encode::VERSION );
    if ($Encode::VERSION) {
      $converter = sub {Encode::from_to( $_[0],$from,$to )};
      my $space = '    ';
      if (eval{&{$converter}($space)}) {
        $code2code{$from,$to} = $converter;
      } else {
        $converter = undef;
      }
    }
  }

# If there is still no converter
#  Make sure we have checked whether the Text::Iconv module is there
#  If the Text::Iconv module is there
#   If successful in obtaining an new converter
#    Save the call to the converter in a closure and save that in the hash

  if (!$converter) {
    eval( 'use Text::Iconv; $Text::Iconv::VERSION ||= ""' )
     unless defined( $Text::Iconv::VERSION );
    if ($Text::Iconv::VERSION) {
      if (my $object = eval{Text::Iconv->new($from,$to)}) {
        $converter = $code2code{$from,$to} =
         sub {$_[0] = $object->convert( $_[0] )};
      }
    }
  }

# If there is still no converter and we're converting to UTF-8
#  Make sure we have checked whether the Text::Iconv module is there
#  If the NexTrieve::UTF8 package is there
#   If successful in obtaining an new converter
#    Save the call to the converter in a closure and save that in the hash

  if (!$converter and $to eq 'utf-8') {
    eval( 'use NexTrieve::UTF8; $NexTrieve::UTF8::VERSION ||= ""' )
     unless defined( $NexTrieve::UTF8::VERSION );
    if ($NexTrieve::UTF8::VERSION) {
      (my $name = "NexTrieve::UTF8::$from") =~ s#-##g;
      $converter = $code2code{$from,$to} =\&{$name} if defined( &{$name} );
    }
  }

# If there is still no converter (no Text::Iconv module available)
#  Create a closure to the generic iconv converter

  if (!$converter) {
    $converter = $code2code{$from,$to} =
     sub {$_[0] = $self->_iconv($from,$to,$_[0])};
  }

# If we don't have a converter
#  Set error
#  Return now empty handed if conversion failed

  unless ($converter) {
    $self->_recoding_error( $from,$to );
    return '';
  }

# Do the recoding
# Return result of recoding process

  &{$converter}( $xml );
  return $xml;
} #recode

#------------------------------------------------------------------------

#  IN: 1..N new remove containers
# OUT: 1..N current/old remove containers

sub removecontainers { shift->_containers( 'remove',@_ ) } #removecontainers

#-------------------------------------------------------------------------

#  IN: 1 string to shorten
#      2 maximal length (3rd parameter to substr)
# OUT: 1 shortened string (ensuring no broken entities)

sub shorten {

# Obtain the object
# Obtain the value, shortened already

  my $self = shift;
  my $value = substr(shift,0,shift);

# Make sure we don't have a broken entity at the end
# Return the shortened value

  $value =~ s#&\w*$##s;
#*** should add encoding check: if utf-X, valid at end?
  return $value;
} #shorten

#-------------------------------------------------------------------------

#  IN: 1 handle to be slurped
#      2 flag: do not close handle
# OUT: 1 data that was slurped

sub slurp {

# Obtain the object
# Obtain the handle
# Return now with nothing if no handle to be read

  my $self = shift;
  my $handle = shift;
  return '' unless $handle;

# Save current slurp setting
# Make sure we'll slurp the file in its entirety
# Slurp the contents
# Close the file
# Restore slurp setting

  my $slurp = $/;
  undef( $/ );
  my $data = <$handle>;
  close( $handle ) unless shift;
  $/ = $slurp;

# Return whatever we got

  return $data || '';
} #slurp

#-------------------------------------------------------------------------

#  IN: 1 handle to be splatted
#      2 data to be splatted
#      3 flag: do not close handle
# OUT: 1 whether successful

sub splat {

# Obtain the object
# Obtain the handle
# Return now with nothing if no handle to be written to

  my $self = shift;
  my $handle = shift;
  return '' unless $handle;

# Write the data to the file
# Close the handle unless inhibited

  my $success = print $handle $_[0];
  close( $handle ) unless $_[1];
  return $success;
} #splat

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
  my $id = $self =~ m#0x([\da-fA-F]+)# ? $1 : 'strange';
  return $self->Tmp."/$root.$$.$id.$extension";
} #tempfilename

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

# IN/OUT: 1 text to be checked/adapted when necessary
# OUT: 1 encoding (utf-8 if converted from utf-32 or utf-16, else '')

sub utf3216check {

# Obtain the object
# Initialize the "from" encoding
# Initialize the "to" encoding

  my $self = shift;
  my $from = '';
  my $to = '';

# If the data starts with a null byte (check for big endian)
#  If there is a charset specification despite the null-bytes
#   Use that, removing the null-bytes on the fly
#   Add big-ending postfix if there is none yet
#  Elseif two lower ascii chars 4-byte padded and length is a multiple of 4
#   Assume ucs-4, big endian
#  Elseif two lower ascii chars 2-byte padded and length is a multiple of 2
#   Assume ucs-2, little endian

  if ($_[0] =~ m#^\0#) {
    if ($_[0] =~ m#c\0+h\0+a\0+r\0+s\0+e\0+t\0+=((?:\0+[\w\-])+)#si) {
      ($from = $1) =~ s#\0##sg;
      $from .= 'be' unless $from =~ m#be$#i;
    } elsif ($_[0] =~ m#^(?:\0{3}[\x01-\x7F]){2}# and !(length($_[0]) & 3)) {
      $from = 'ucs-4be';
    } elsif ($_[0] =~ m#^(?:\0[\x01-\x7F]){2}# and !(length($_[0]) & 1)) {
      $from = 'ucs-2be';
    }

# Elseif the second byte is a null byte (check for little endian)
#  If there is a charset specification despite the null-bytes
#   Use that, removing the null-bytes on the fly
#   Add little endian postfix if there is none yet
#  Elseif two lower ascii chars 4-byte padded and length is a multiple of 4
#   Assume utf-32, little endian
#  Elseif two lower ascii chars 2-byte padded and length is a multiple of 2
#   Assume utf-16, little endian

  } elsif ($_[0] =~ m#^.\0#) {
    if ($_[0] =~ m#c\0+h\0+a\0+r\0+s\0+e\0+t\0+=((?:\0+[\w\-])+)#si) {
      ($from = $1) =~ s#\0##sg;
      $from .= 'le' unless $from =~ m#le$#;
    } elsif ($_[0] =~ m#^(?:[\x01-\x7F]\0{3}){2}# and !(length($_[0]) & 3)) {
      $from = 'ucs-4le';
    } elsif ($_[0] =~ m#^(?:[\x01-\x7F]\0){2}# and !(length($_[0]) & 1)) {
      $from = 'ucs-2le';
    }
  }

# Convert to UTF-8 if we have a "from" encoding, setting "to" on the fly
# Return the encoding we encoded "to"

  $_[0] = $self->recode( $to = 'utf-8',$_[0],$from ) || '' if $from;
  return $to;
} #utf3216check

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

#  IN: 1 new setting of the xmllint flag (default: no change)
# OUT: 1 current/old setting of xmllint flag

sub xmllint {

# Obtain the object
# If we want to use xmllint and it appears to be available
#  Obtain the first line and return setting flag if found
# Else (no usage or no xmllint
#  Lose whatever parameter there may be

  my $self = shift;
  if ($_[0] and
   my $handle = eval{$self->openfile( "xmllint --version 2>&1|" )}) {
    return $self->_class_variable(
     'xmllint',$self->slurp( $handle ) =~ m#^xmllint: using libxml# );
  } else {
    shift;
  }

# Return whatever is returned from normal handling

  return $self->_class_variable( 'xmllint',@_ );
} #xmllint

#------------------------------------------------------------------------

# Following subroutines are inheritable, not to be used by NexTrieve.pm itself

#------------------------------------------------------------------------

#  IN: 1..N reference to list with name of attribute and coderef or keyword

sub attribute_processor {
 shift->_processor_definition( 'attr',\%standardprocessor,@_ )
} #attribute_processor

#------------------------------------------------------------------------

# OUT: 1 command last executed

sub command { $_[0]->{ref(shift).'::command'} } #command

#------------------------------------------------------------------------

#  IN: 1 new indexdir override
# OUT: 1 old/current indexdir override

sub indexdir { shift->_class_variable( 'indexdir',@_ ) } #indexdir

#-------------------------------------------------------------------------

#  IN: 1 name of executable
# OUT: 1 full program name ('' if not found or not executable)
#      2 expiration date of license ('' if not known)
#      3 software version
#      4 database version
#      5 whether threaded or not

sub executable {

# Obtain the class
# Obtain the NexTrieve object, either new or from the calling object
# Create the program name

  my $class = shift;
  my $ntv = ref($class) ? $class->NexTrieve : $class->new;
  my $program = $ntv->NexTrievePath.'/'.shift;

# If it is executable
#  Return now if we only want the flag
# Else
#  Return the bad result now

  if (-x $program) {
    return $program unless wantarray;
  } else {
    return wantarray ? ('') : '';
  }

# Open a pipe to the executable
# If it failed
#  Return the bad result now
# Read the info

  my $handle = $ntv->openfile( "$program -V|" );
  unless ($handle) {
    return wantarray ? ('') : '';
  }
  my $info = $ntv->slurp( $handle );

# Obtain the software version info
# Obtain the index version info
# Obtain the threaded flag
# Obtain the license info

  my $software = $info =~ s#\s*Software\s+([\d\.]+)\s*,?## ? $1 : '';
  my $index = $info =~ s#\s*Index\s+([\d\.]+)\s*,?## ? $1 : '';
  my $threaded = $info =~ s#\s*threaded\s*,?##;
  my $license = $info =~ s#\s*Licensed\s+until\s*([\d\-]+)\s*,?## ? $1 : '';
  
# Normalize the license info to a datestamp YYYYMMDD
# Return the result of all this

  $license =~ s#-##g;
  return ($program,$license,$software,$index,$threaded);
} #executable

#------------------------------------------------------------------------

#  IN: 1..N names/list refs of attributes to be added extra

sub extra_attribute { shift->_extra_definition( 'attr',@_ ) } #extra_attribute

#------------------------------------------------------------------------

#  IN: 1..N names/list refs of texttypes to be added extra

sub extra_texttype { shift->_extra_definition( 'text',@_ ) } #extra_texttype

#------------------------------------------------------------------------

#  IN: 1..N names/list refs of fields to be added as attributes

sub field2attribute { shift->_field_definition( 'attr',@_ ) } #field2attribute

#------------------------------------------------------------------------

#  IN: 1..N names/lists refs of fields to be added as texttypes

sub field2texttype { shift->_field_definition( 'text',@_ ) } #field2texttype

#------------------------------------------------------------------------

# OUT: 1 integrity report

sub integrity {

# Obtain the object

  my $self = shift;

# Obtain the index directory
# If there is no index directory
#  Add error and return

  my $indexdir = $self->indexdir || $self->Resource->indexdir;
  unless ($indexdir) {
    $self->_add_error( "Must know which index to check" );
    return;
  }

# Obtain local copy of the command and store in object
# Attempt to open a pipe
# Return now if failed

  my $command = $self->{ref($self).'::command'} =
   $self->NexTrievePath.'/ntvcheck';
  my $handle = $self->openfile( "$command $indexdir|" );
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
  my $handle = $self->openfile( $log,'<' );
  return unless $handle;

# Set the field name for the position to read from
# Make sure we start there

  my $field = ref($self).'::READFROM';
  seek( $handle,$self->{$field} || 0,0 );

# Obtain the result
# Keep current position to read from next time
# Close the handle

  my $result = $self->slurp( $handle,1 );
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

  if (my $handle = $self->openfile( $filename,'<' )) {
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

#  IN: 1 flag: whether to skip (resets if nothing or false is specified)
# OUT: 1 flag: whether to skip

sub skip {

# Obtain the object
# Obtain the flag
# Create the field name
# Obtain the current value

  my $self = shift;
  my $flag = shift;
  my $field = ref($self).'::skip';
  my $old = $self->{$field} || '';

# If there is a new true value
#  Set that in the object
# Else
#  Remove the key from the object
# Return whatever was the old (or non-existant) value

  if ($flag) {
    $self->{$field} = $flag;
  } else {
    delete( $self->{$field} );
  }
  return $old;
} #skip

#------------------------------------------------------------------------

#  IN: 1..N reference to list with name of texttype and coderef or keyword

sub texttype_processor {
 shift->_processor_definition( 'text',\%standardprocessor,@_ )
} #texttype_processor

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
} #write_file

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
# Obtain the class
# Create the field name
# Obtain the XML if we don't have it yet
# Return what we have already or create the XML out of the DOM

  my $self = shift;
  my $class = ref($self);
  my $field = $class.'::xml';
  $self->{$field} ||= $self->_create_xml;
  return $self->{$field} unless $self->xmllint;

# Create the temporary filename
# Initialize the processor instruction
# If there is no processor instruction in the XML
#  Obtain the encoding
#  Create a processor instruction with that
# Write the XML to be checked

  my $tempfilename = $self->tempfilename( 'xmllint' );
  my $pi = '';
  unless ($self->{$field} =~ m#^<\?xml#) {
    my $encoding =
     $self->{$class.'::encoding'} || $self->DefaultInputEncoding;
    $pi = qq(<?xml version="1.0" encoding="$encoding"?>\n) if $encoding;
  }
  $self->splat( $self->openfile( $tempfilename,'>' ),$pi.$self->{$field} );

# Obtain the converted XML
# Remove the temporary filename

  my $errors = $self->slurp(
   $self->openfile( "xmllint --noout $tempfilename 2>&1|" ) );
  unlink( $tempfilename );

# If there are any errors
#  Remove all the temporary file references
#  Add an error saving them
#  And return with nothing

  if ($errors) {
    $errors =~ s#$tempfilename:##sg;
    $self->_add_error( "xmllint found these errors:\n$errors" );
    return '';
  }

# Return the XML

  return $self->{$field};
} #write_string

#-------------------------------------------------------------------------

#  IN: 1 new XML
# OUT: 1 old/current XML

sub xml {

# Obtain the object
# Obtain the XML if not called in a void context
# Show the XML to the world if called in void context without new setting

  my $self = shift;
  my $xml = $self->write_string || '';
  warn $xml unless defined(wantarray) or @_;

# Create new XML if specified
# Return whatever the XML was

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
  $self->Set( shift ) if ref($_[0]) eq 'HASH';
  $self->_filename_xml( @_ ) if $_[0];
  return $self;
} #_new_from_filename_xml

#-------------------------------------------------------------------------

#  IN: 1 filename or xml specification
#      2 type specification

sub _filename_xml {

# Obtain the object
# Obtain the filename or XML
# Obtain the type of parameter

  my $self = shift;
  my $filename = shift;
  my $type = shift;

# If there is a filename
#  If it is a hash reference
#   Assume we're setting multiple values

  if ($filename) {
    if (ref($filename) =~ m#^(?:ARRAY|HASH)$#) {
      $self->Set( $filename );

#  Elseif there is no defined type
#   If there is no newline and it can be a filename and the file exists
#    Read that file
#   Else (assume it is direct content)
#    Read that string

    } elsif (!defined($type)) {
      if ($filename !~ m#\n#s and length($filename) < 256 and -s $filename) {
        $self->read_file( $filename );
      } else {
        $self->read_string( $filename );
      }

# Else (we have a defined type)
#  Call the generic content fetcher and use that as a string

    } else {
      $self->read_string( $self->_fetch_content( $filename,$type,@_ ) );
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
# Create local copy of original NexTrieve object

  my $self = shift;
  my $ntv = shift || $self->{'Nextrieve'};

# For names of all of the fields that we need to copy
#  Copy the value

  foreach (qw(
   DefaultInputEncoding
   RaiseError
   NexTrievePath
   NexTrieveVersion
   PrintError
   Tmp
    )) {
    $self->{$_} ||= $ntv->{$_} if exists $ntv->{$_};
  }
  return $self;
} #_inherit

#------------------------------------------------------------------------

#  IN: 1 name of container
#      2 content to add (direct, ref to list or scalar)
# OUT: 1 ready-to-use XML

sub _add_container {

# Obtain the object
# Obtain the name
# Obtain the line
# Initialize xml

  my $self = shift;
  my $name = shift;
  my $line = shift || '';
  my $xml = '';

# Create the before and after container (empty if no name)

  my $before = $name ? "<$name>" : '';
  my $after =  $name ? "</$name>" : '';

# If we were passed back a reference to a list
#  For all the elements in that list
#   Add a container for it
# Elseif we have a reference to a scalar
#  Just return the container for that reference if there is something there
# Elseif we have something
#  Just return the container

  if (ref($line) eq 'ARRAY') {
    foreach (@{$line}) {
      $xml .= "$before$_$after\n" if length($_);
    }
  } elsif (ref($line) eq 'SCALAR') {
    return "$before$$line$after\n" if length($$line);
  } elsif (length($line)) {
    return "$before$line$after\n";
  }

# Return now with the XML (if it was not a simple string)

  return $xml;
} #_add_container

#-------------------------------------------------------------------------

#  IN: 1 error message to add
# OUT: 1 object itself (for handy oneliners)

sub _add_error {

# Obtain the object
# Save whatever was specified as an error
# Save the error on the list
# Show the warning if we're supposed to

  my $self = shift;
  my $message = shift;
  push( @{$self->{ref($self).'::Errors'}},$message );
  warn "$message\n" if $self->{'PrintError'};

# If we're to die on errors
#  If it is a code reference
#   Execute it, passing the message as a parameter
#  Else
#   Eval what we had as a value
#  Die now if we hadn't died already
  
  if (my $action = $self->{'RaiseError'}) {
    if (ref($action) eq 'CODE') {
      &{$action}( $message );
    } else {
      eval( $action );
    }
    die "$message\n";
  }

# Return the object again

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
  my $command = $self->executable( $filename );

# If the binary does not exist
#  Add error to object and return

  unless ($command) {
    $self->_add_error( "Cannot find program $filename" );
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

  my $indexdir = $self->indexdir;
  $self->indexdir( $indexdir = $resource->indexdir ) unless $indexdir;
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

  my $log = $self->log;
  $self->log( $log = "$indexdir/$filename.log" ) unless $log;
  $self->{ref($self).'::READFROM'} = -e $log ? -s _ : 0;
  return ($command,$log,$indexdir);
} #_command_log

#------------------------------------------------------------------------

#  IN: 1 name of container type
#      2..N new list of containers
# OUT: 1..N old list of containers (concatenated with | if in scalar context)

sub _containers {

# Obtain the object
# Create the field name
# Obtain the current value

  my $self = shift;
  my $field = ref($self).'::'.scalar(shift).'containers';
  my $old = $self->{$field};

# Set the new value if any were specified
# Return as list if in a list context
# Return as string otherwise

  $self->{$field} = join( '|',@_ ) if @_;
  return split( '|',$old ) if wantarray;
  return $old;
} #_containers

#------------------------------------------------------------------------

#  IN: 1 line to be converted
#      2 attribute name to be used
#      3 document object being created
# OUT: 1 value for which to add attribute

sub _datestamp { _datetimestamp( '%04d%02d%02d',shift ) } #_datestamp

#------------------------------------------------------------------------

#  IN: 1 format to be used for printing
#      2 line to be converted
# OUT: 1 date/timestamp or '' if could not be converted

sub _datetimestamp {

# Obtain the format
# Obtain the line to work with

  my $format = shift;
  my $line = shift;

# Convert to epoch time unless it is already epoch
# If failed (usually because of an unknown timezone specification)
#  Attempt to remove any timezone specification
#  Try to convert to epoch time again

  my $epoch = $line =~ m#^\d+$# ? $line : Date::Parse::str2time( $line ) || '';
  unless ($epoch) {
    $line =~ s#\s*\w{3}\s*$##;
    $epoch = Date::Parse::str2time( $line );
  }

# Return now if we cannot distill an epoch time
# Return now if we don't have a format (epoch time requested)

  return '' unless $epoch;
  return $epoch unless $format;

# Convert to epoch time and get its constituent parts
# Put them together into a datestamp (YYYYMMDD) and return it

  my ($second,$minute,$hour,$day,$month,$year) = gmtime( $epoch );
  return sprintf( $format,$year+1900,$month+1,$day,$hour,$minute,$second );
} #_datetimestamp

#------------------------------------------------------------------------

#  IN: 1 line to be converted
#      2 attribute name to be used
#      3 document object being created
# OUT: 1 value for which to add attribute

sub _epoch { _datetimestamp( '',shift ) } #_epoch

#------------------------------------------------------------------------

#  IN: 1 prefix of hash ref in object
#      2..N values to be added (none: reset)

sub _extra_definition {

# Obtain the object
# Create the field name for the list of info

  my $self = shift;
  my $field = ref($self).'::'.scalar(shift).'extra';

# If there are any new values
#  Reset the list if so requested
#  For all of the new values
#   Obtain the coderef from the list
#   Obtain the key from the list
#   Save the coderef, the key and the rest of the list

  if (@_) {
    delete( $self->{$field} ),shift(@_) if $_[0] eq 'reset';
    foreach my $ref (@_) {
      my $coderef = shift(@{$ref});
      my $key = lc(shift(@{$ref}));
      push( @{$self->{$field}},[$coderef,$key,@{$ref}] );
    }

# Else (no values, reset requested)
#  Remove the field

  } else {
    delete( $self->{$field} );
  }
} #_extra_definition

#------------------------------------------------------------------------

#  IN: 1 id we need to fetch content for
#      2 type of fetch to perform
# OUT: 1 content fetched
#      2 id to be used
#      3 epoch time of last modification (when applicable)
#      4 source of information (when applicable)

sub _fetch_content {

# Obtain the object
# Obtain the ID we need to work on
# Obtain the type of fetch we need to do

  my $self = shift;
  my $id = shift;
  my $type = shift;

# If we don't have a type yet
#  Assume URL type fetch if the id seems to contain a protocol specification

  if (!defined($type)) {
    $type = 'url' if $id =~ m#^\w+://#;
  }

# If we have a defined type
#  Set the initial fetcher reference
#  If we still don't have one, use the subroutine ref if it is a subroutine ref
#  Return the result of the fetch if we have a fetcher now

  if (defined($type)) {
    my $fetcher = $contentfetcher{$type};
    $fetcher ||= $type if ref($type) eq 'CODE';
    return &{$fetcher}( $self,$id,@_ ) if $fetcher;

# Else (we don't have a defined type)
#  Return result of direct fetch if so indicated
#  Return result of filename fetch

  } else {
    return $self->_fetch_direct( $id ) if $id =~ m#\n#s or ref($id) eq 'ARRAY';
    return $self->_fetch_from_filename( $id );
  }

# Add error
# Return without contenT

  $self->_add_error( "Could not fetch content for type '".($type || '')."'" );
  return wantarray ? ('',$id,'') : '';
} #_fetch_content

#------------------------------------------------------------------------

#  IN: 1 indication of content to fetch
# OUT: 1 content fetched
#      2 id to be used
#      3 epoch time of last modification
#      4 source of information

sub _fetch_direct {

# Return now if the simplest case

  return $_[1] if !wantarray and !ref($_[1]);

# Obtain the object
# Return now if a reference to a list
# Return what we got otherwise

  my $self = shift;
  return (wantarray ? (@{$_[0]},'','') : $_[0]->[0]) if ref($_[0]) eq 'ARRAY';
  return $_[0];
} #_fetch_direct

#------------------------------------------------------------------------

#  IN: 1 id we need to fetch content for
#      2 type of fetch to perform
# OUT: 1 filename fetched into
#      2 id to be used
#      3 epoch time of last modification (when applicable)
#      4 source of information (when applicable)

sub _fetch_file {

# Obtain the object
# Obtain the filename we need to work on
# Obtain the type of fetch we need to do

  my $self = shift;
  my $filename = shift;
  my $type = shift || '';

# If we are working with a local file
#  Return now if we only want the filename
#  Obtain the id
#  Obtain the last modified stuff
#  Return now with all the parameters

  if ($type eq 'file' or (!ref($filename) and $filename !~ m#\n#s)) {
    return $filename unless wantarray;
    my $id = $filename =~ s#:(\w+)$## ? $1 : $filename;
    my $lastmod = (stat($filename))[9];
    return ($filename,$id,$lastmod,$filename);
  }

# Obtain the content
# If there was no content
#  Return now

  my ($content,$id,$lastmod,$source) = $self->_fetch_content( $filename,$type );
  unless ($content) {
    return wantarray ? ('',$id,'') : '';
  }

# Obtain a temporary filename
# Write the contents there
# Save the filename for automatic destruction
# Return the parameters

  $filename = $self->tempfilename( 'fetch' );
  $self->splat( $self->openfile( $filename,'>' ),$content );
  push( @{$self->{'unlink'}},$filename );
  return wantarray ? ($filename,$id,$lastmod,$source) : $filename;
} #_fetch_file

#------------------------------------------------------------------------

#  IN: 1 indication of content to fetch
# OUT: 1 content fetched
#      2 id to be used
#      3 epoch time of last modification
#      4 filename used for opening the file

sub _fetch_from_filename {

# Obtain the object
# Obtain the filename
# Obtain the ID

  my $self = shift;
  my $filename = shift;
  my $id = $filename =~ s#:(\w+)$## ? $1 : $filename;

# If it is possible to open the file, obtaining handle on the fly
#  Obtain the last modified info
#  Obtain the content

  if (my $handle = $self->openfile( $filename,'<' )) {
    my $lastmodified = (stat($handle))[9];
    my $content = $self->slurp( $handle );

#  Obtain the class
#  Set the filename of the object
#  Mark it as being ok when appropriate
#  Return now with what is requested

    my $class = ref($self);
    $self->{$class.'::filename'} = $filename;
    $self->{$class.'::FILEOK'} = exists( $self->{$class.'::version'} );
    return wantarray ? ($content,$id,$lastmodified,$filename) : $content;
  }

# Add error
# Return with what can be returned
  
  $self->_add_error( "Could not open file '$filename': $!" );
  return wantarray ? ('',$id,'',$filename) : '';
} #_fetch_from_filename

#------------------------------------------------------------------------

#  IN: 1 indication of content to fetch
# OUT: 1 content fetched
#      2 id to be used
#      3 epoch time of last modification
#      4 source of information

sub _fetch_from_url {

# Obtain the object
# Obtain the ID
# Obtain the url (to be able to work with it later)

  my $self = shift;
  my $id = shift;
  my $url = $id;

# Obtain the protocol
# Return now the result of filehandling if protocol is 'file'

  my $protocol = $url =~ s#^(\w+)://## ? $1 : 'http';
  return $self->_fetch_from_filename( $url ) if $protocol eq 'file';

# Initialize the error message
# If successful in obtaining host + optional port specification
#  Obtain the port specification, either from URL or by default
#  Make sure there is something to be fetched
#  Make sure we don't get a problem fetching the version
#  Obtain the user agent name to be used
#  If there is content to be obtained

  my $error = '';
  if (my $host = $url =~ s#^(.*?)(?=/)## ? $1 : '') {
    my $port = $host =~ s#:(\d+)$## ? $1 : 80;
    $url ||= '/';
    no strict 'refs';
    my $agent = ref($self); $agent .= " (${$agent.'::VERSION'})";
    if (my $content = $self->ask_server_port(
     [PeerAddr => "$host:$port",Timeout => 10,],<<EOD)) {
GET $url HTTP/1.0
Host: $host
User-Agent: $agent

EOD

#   Split off the header from the content
#   If the status is ok
#    Obtain last modified info if any
#    Return now with what is requested

      my $header = $content =~ s#^(.*?\r?\n)\r?\n##s ? $1 : '';
      if ($header =~ m#\b(\d{3})\b\s*(.*)\r# and $1 == 200) {
        my $lastmodified = $header =~ m#last-modified:(.*?)\n#si ?
         _epoch($1) : '';
        return wantarray ? ($content,$id,$lastmodified,$id) : $content;

#   Else (status was not ok)
#    Set error to the returned status
#  Else (could not talk to server)
#   Set whatever we got from the system as error

      } else {
        $error = "$1 ($2)";
      }
    } else {
      $error = $!;
    }
  }

# Add error
# Return with what can be returned
  
  $self->_add_error( "Could not open url '$id': $error" );
  return wantarray ? ('',$id,'') : '';
} #_fetch_from_url

#------------------------------------------------------------------------

#  IN: 1 prefix of hash ref in object
#      2..N values to be added

sub _field_definition {

# Obtain the object
# Create the field name
# Initialize the key

  my $self = shift;
  my $field = ref($self).'::'.scalar(shift).'hash';
  my $key;

# For all of the parameters
#  Obtain local copy of the value
#  If we got a reference to a list
#   Obtain the key from the list
#  Else (assume just a key)
#   Make sure that the key is all lowercase
#   Create an empty list ref
#  Save the parameters and the key

  foreach (@_) {
    my $ref = $_;
    if (ref($ref) eq 'ARRAY') {
      $key = lc(shift(@{$ref}));
    } else {
      $key = lc($ref);
      $ref = [];
    }
    $self->{$field}->{$key} = $ref;
  }
} #_field_definition

#------------------------------------------------------------------------

#  IN: 1 document object to work on
#      2 id of source object
#      3 reference to content hash
#      4 base container text
#      5 name of normalization method

sub _hashprocextra {

# Obtain the object
# Obtain the class of the object
# Obtain the rest of the parameters

  my $self = shift;
  my $class = ref($self);
  my ($document,$id,$content,$text,$normalize) = @_;

# Obtain local copy of attribute hash
# Obtain local copy of attribute processor hash
# Obtain local copy of texttype hash
# Obtain local copy of texttype processor hash

  my $attrhash = $self->{$class.'::attrhash'} || {};
  my $attrproc = $self->{$class.'::attrproc'} || {};
  my $texthash = $self->{$class.'::texthash'} || {};
  my $textproc = $self->{$class.'::textproc'} || {};

# Obtain local copy of extra attribute list
# Obtain local copy of extra texttype list

  my $attrextra = $self->{$class.'::attrextra'} || [];
  my $textextra = $self->{$class.'::textextra'} || [];

# Initialize the attributes
# For all of the extra attributes
#  Obtain the extra attributes

  my $attributes = '';
  foreach my $list (@{$attrextra}) {
    $attributes .= $self->_process_container(
     $list->[1],$id,$list->[0],$document,$normalize );
  }

# For all of the attributes that should be created
#  Reloop if nothing to be handled
#  Obtain the name for the container
#  Process the container for this attribute

  foreach my $key (sort keys %{$attrhash}) {
    next unless exists $content->{$key};
    my $name = $attrhash->{$key}->[0] || $key;
    $attributes .= $self->_process_container(
     $name,$content->{$key},$attrproc->{$name},$document,$normalize );
  }

# Initialize the texttypes
# For all of the extra texttypes
#  Obtain the extra texttypes

  my $texts = '';
  foreach my $list (@{$textextra}) {
    $texts .= $self->_process_container(
     $list->[1],$id,$list->[0],$document,$normalize );
  }

# For all of the texttypes that should be created
#  Reloop if nothing to be handled
#  Obtain the name for the container
#  Process the container for this attribute

  foreach my $key (sort keys %{$texthash}) {
    next unless exists $content->{$key};
    my $name = $texthash->{$key}->[0] || $key;
    $texts .= $self->_process_container(
     $name,$content->{$key},$textproc->{$name},$document,$normalize );
  }

# If there is text to process
#  Remove whitespace on the outside of the remaining text
#  Process the remaining text as an empty container

  if ($text) {
    $text =~ s#^\s+##s; $text =~ s#\s+$##s;
    $texts .= $self->_process_container( '',$text,$textproc->{''},$document );
  }

# If we're to skip this document
#  Delete the XML from the document
#  And return now

  if ($document->skip) {
    delete( $document->{ref($document).'::xml'} );
    return;
  }

# Containerize the attributes if there are any
# Containerize the texts if any

  $attributes = "<attributes>\n$attributes</attributes>\n" if $attributes;
  $texts = "<text>\n$texts</text>\n" if $texts;

# Set the XML in the document

  $document->{ref($document).'::xml'} = <<EOD;
<document>
$attributes$texts</document>
EOD
} #_hashprocextra

#-------------------------------------------------------------------------
#  IN: 1 value to check for intext encoding
# OUT: 1 possibly adapted value

sub _intext_recode {

# Obtain the object
# Obtain the value
# Return now if nothing to test

  my $self = shift;
  my $value = shift;
  return '' unless defined($value);

# Do the test, change where appropriate
# Return the possibly adapted value

  $value =~ s#=\?(.*?)\?Q\?(.*?)\?=#$self->recode('intext',$2,$1)#sge;
  return $value;
} #_intext_recode

#-------------------------------------------------------------------------

#  IN: 1 encoding to normalize
# OUT: 1 normalized encoding

sub _normalize_encoding {

# Obtain the object if there is one
# Obtain the lowercase encoding
# Get rid of any special characters
# Replace underscores with dashes

  shift if ref($_[0]);
  my $encoding = lc(shift);
  $encoding =~ s#[^\w\-\_]##sg;
  $encoding =~ s#_#-#sg;

# Apply some heuristics for broken encoding names

  $encoding =~ s#^(?:iso)?-?(?:latin|885\d)-?#iso-8859-#s;
  $encoding = 'iso-8859-1' if $encoding =~ m#^(?:html|us-ascii)$#;
  $encoding = 'utf-8' if $encoding =~ m#^(?:utf-?2)$#;
  $encoding = "ucs-2$1" if $encoding =~ m#^(?:ucs-?2|utf-?16)(\w*)$#;
  $encoding = "ucs-4$1" if $encoding =~ m#^(?:ucs-?4|utf-?32)(\w*)$#;

# And return the result

  return $encoding;
} #_normalize_encoding

#------------------------------------------------------------------------

#  IN: 1 name of container
#      2 line/parameter to process
#      3 processor
#      4 document object
#      5 normalizing method if no processor
# OUT: 1 XML to be added

sub _process_container {

# Obtain the parameters
# Initialize the XML

  my ($self,$name,$todo,$proc,$document,$normalize) = @_;
  my $xml = '';

# Create the before and after container (empty if no name)

  my $before = $name ? "<$name>" : '';
  my $after =  $name ? "</$name>" : '';

# If the processor is a reference to a scalar
#  Make whatever is sitting there what we need to handle
#  Reset processing information

  if (ref($proc) eq 'SCALAR') {
    $todo = $$proc;
    $proc = '';
  }

# If there is a processor
#  If we were told to process a list
#   For all of the entries in the list
#    Obtain the value from the processor, checked for intext recoding
#    Make sure it's normalized the way we want it
#    Add the result

  if ($proc) {
    if (ref($todo) eq 'ARRAY') {
      foreach (@{$todo}) {
        my $value = $document->_intext_recode( &{$proc}( $_,$name,$document ) );
        $self->$normalize( $value ) if $normalize;
        $xml = "$before$value$after\n" if length($value);
      }

#  Else (single value only)
#   Obtain the value from the processor, checked for intext recoding
#   Make sure it's normalized the way we want it
#   Add the result

    } else {
      my $value = $document->_intext_recode( &{$proc}( $todo,$name,$document ));
      $self->$normalize( $value ) if $normalize;
      $xml = "$before$value$after\n" if length($value);
    }

# Elseif we have a list to process (and no processor)
#  For all of the entries in the list
#   Obtain the value, checked for intext recoding
#   Make sure the line is clean using the specified normalization if any
#   Add the text for it if there is something to add

  } elsif (ref($todo) eq 'ARRAY') {
    foreach (@{$todo}) {
      my $value = $document->_intext_recode( $_ );
      $self->$normalize( $value ) if $normalize;
      $xml .= "$before$value$after\n" if length($value);
    }

# Elseif we have something to process (and no processor)
#  Make sure we have a local copy of the value, checked for intext recoding
#  Make sure the line is clean using the specified normalization if any
#  Add the text for it

  } elsif (defined($todo) and length($todo)) {
    my $value = $document->_intext_recode( $todo );
    $self->$normalize( $value ) if $normalize;
    $xml = "$before$value$after\n";
  }

# Return the created XML

  return $xml;
} #_process_container

#------------------------------------------------------------------------

#  IN: 1 prefix of hash ref in object
#      2 reference to defined processor hash
#      2..N references to list with name and coderef pairs or keywords

sub _processor_definition {

# Obtain the object
# Create the field name

  my $self = shift;
  my $field = ref($self).'::'.scalar(shift).'proc';
  my $processorhash = shift;

# For all of the keys specified
#  Obtain the key
#  Obtain the code ref

  foreach my $list (@_) {
    my $key = $list->[0];
    my $coderef = $list->[1];

#  If a coderef or keyword was specified
#   Obtain the standard coderef if there is one or just use what was given
#  Else (apparently they want us to remove the code ref)
#   Remove the key from the hash

    if ($coderef) {
      $self->{$field}->{$key} = $processorhash->{$coderef} || $coderef;
    } else {
      delete( $self->{$field}->{$key} );
    }
  }
} #_processor_definition

#-------------------------------------------------------------------------

#  IN: 1 server:port or port specification or reference to list with hash
# OUT: 1 socket (undef if error)

sub _socket {

# Obtain the object
# Obtain the hash of the parameters
# Set the default host if only a port number specified

  my $self = shift;
  my %hash = ref($_[0]) eq 'ARRAY' ? @{shift()} : (PeerAddr => shift);
  $hash{'PeerAddr'} = "localhost:$hash{'PeerAddr'}"
   if exists( $hash{'PeerAddr'} ) and $hash{'PeerAddr'} =~ m#^\d+$#;

# Attempt to open a socket there
# Set error if failed
# Return whatever we got

  my $socket = IO::Socket::INET->new( %hash );
  $self->_add_error( "Error connecting to socket: $@" )
   unless $socket;
  return $socket;
} #_socket

#------------------------------------------------------------------------

#  IN: 1 line to be converted
#      2 attribute name to be used
#      3 document object being created
# OUT: 1 value for which to add attribute

sub _timestamp { _datetimestamp('%04d%02d%02d%02d%02d%02d',shift) } #_timestamp

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
    while (my ($name,$value) = each %{$self->{$field}}) {
      push( @old,[$name,@{$value}{@key}] );
    }
  }

# If we should set the new set of attributes
#  Initialize the new hash with attributes
#  Initialize the reference to the hash with the previous values

  if (@_ or (!@_ and !defined(wantarray))) {
    my $new = {};

#  While there are parameters to be processed
#   Initialize the name for this attribute
#   Initialize the hash for this attribute
#   For all of the possible fields
#    Copy the value from the previously specified one

    while (my $ref = shift) {
      my $name;
      my %this;

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
      $new->{$name} = \%this;
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

  my $version = $self->{$class.'::version'};
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
# If we're supposed to output the processor instruction
#  Obtain the encoding
#  Add encoding if there is any

  my $xml = '';
  unless ($self->nopi) {
    my $encoding =
     $self->{$class.'::encoding'} || $self->DefaultInputEncoding;
    $xml .= <<EOD if $encoding;
<?xml version="1.0" encoding="$encoding"?>
EOD
  }

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
  foreach (sort keys %{$hash}) {
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
  my $xml = shift;

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
  foreach (sort keys %{$hash}) {
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
  my $list = shift;

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
  my $list = shift;

# Initialize the XML
# For all of the keys in the hash that we need to process
#  Add to the XML if there is something to add
# Return the final result, always starts with a space

  my $xml = '';
  foreach ($list ? @{$list} : sort keys %{$hash}) {
    $xml .= qq( $_="$hash->{$_}") if $hash->{$_};
  }
  return $xml;
} #_hash2attributes

#------------------------------------------------------------------------

# Internal initialization subroutines

#------------------------------------------------------------------------

# OUT: 1 default display containers

sub _default_displaycontainers {

# Create the list of displaycontainers for matching (no space around it)

  return join( '|',qw(
   a
   b
   em
   font
   i
   strike
   strong
   tt
   u
  ) );
} #_default_displaycontainers

#------------------------------------------------------------------------

# OUT: 1 default remove containers

sub _default_removecontainers {

# Create the list of containers of which the content will be removed

  return join( '|',qw(
   embed
   script
  ) );
} #_default_removecontainers

#------------------------------------------------------------------------

# Internal subroutines, in case there is no local copy

#------------------------------------------------------------------------

sub _create_dom {} #_create_dom

#------------------------------------------------------------------------

sub _delete_dom {} #_delete_dom

#-------------------------------------------------------------------------

# recoding subroutines

#-------------------------------------------------------------------------

#  IN: 1 encoding from
#      2 encoding to
#      3 flag: whether something was returned

sub _recoding_error {

# Obtain the parameters
# Create the field
# Create the filename string
# Do the warning

  my ($self,$from,$to,$something) = @_;
  my $field = ref($self).'::SOURCE';
  my $filename = exists( $self->{$field} ) ? "$self->{$field}: " : '';
  warn $something ?
   "${filename}Error in converting from '$from' to '$to'\n" :
   "${filename}Cannot convert from '$from' to '$to'\n";
} #_recoding_error

#-------------------------------------------------------------------------

#  IN: 1 encoding of XML now
#      2 encoding of XML to be
#      3 XML to convert
# OUT: 1 re-encoded XML or empty string if re-encoding failed

sub _iconv {

# Obtain the object
# Obtain the FROM encoding
# Obtain the TO encoding

  my $self = shift;
  my $from = _normalize_encoding( shift );
  my $to = _normalize_encoding( shift );

# Create the temporary input filename
# Write the XML to be converted
# Return now if nothing was written
# Create the temporary output filename

  my $in = $self->tempfilename( '_iconv.in' );
  $self->splat( $self->openfile( $in,'>' ),$_[0] );
  return '' unless -e $in; # TEMPORARY SOLUTION
  my $out = $self->tempfilename( '_iconv.out' );

# Initialize the XML
# If there is a wrong exit status after the conversion
#  Add recoding error
# Else (everything hunky dory)
#  Get the converted XML

  my $xml = '';
  if (system( "iconv -f $from -t $to $in >$out" )) {
    $self->_recoding_error( $from,$to,(-e $out and -s _) );
  } else {
    $xml = $self->slurp( $self->openfile( $out,'<' ) );
  } 

# Remove the temporary filenames
# Return the XML that was found

  unlink( $in,$out );
  return $xml;
} #_iconv

#-------------------------------------------------------------------------

# subroutines for standard Perl features

#-------------------------------------------------------------------------

sub DESTROY {

# Obtain the object
# Unlink any files that should be removed

  my $self = shift;
  unlink( @{$self->{'unlink'}} ) if exists $self->{'unlink'};
} #DESTROY

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
   Collection::Index
   Daemon
   DBI
   Docseq
   Document
   Hitlist
   Hitlist::Hit
   HTML
   Index
   Mbox
   Message
   MIME
   PDF
   Query
   Querylog
   Replay
   Resource
   RFC822
   Search
   Targz
   UTF8
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

#------------------------------------------------------------------------

# The following methods are for the hidden NexTrieve::handle object

# my $handle = bless \$multilinestring,'NexTrieve::handle';

#------------------------------------------------------------------------

# OUT: 1 number of bytes left in object

sub NexTrieve::handle::left {
 length(${$_[0]}) - pos(${$_[0]}) } #NexTrieve::handle::left

#------------------------------------------------------------------------

# OUT: 1 next line from object (with newline)

sub NexTrieve::handle::next {
 ${$_[0]} =~ m#\G(.*?\r?(?:\n|\Z))#sgc ? $1 : '' } #NexTrieve::handle::next

#------------------------------------------------------------------------

# OUT: 1 next line from object (without newline)

sub NexTrieve::handle::nextnonewline {
 ${$_[0]} =~ m#\G(.*?)\r?(?:\n|\Z)#sgc ? $1 : ''
} #NexTrieve::handle::nextnonewline

#------------------------------------------------------------------------

# OUT: 1 rest of object

sub NexTrieve::handle::rest {
 ${$_[0]} =~ m#\G(.*)#sgc ? $1 : '' } #NexTrieve::handle::rest

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

Provide a Perl interface to the complete functionality of the NexTrieve search
engine sofware as found on http://www.nextrieve.com .

See the NexTrieve::Overview documentation for a introduction of the NexTrieve
search engine software and an overview of how the Perl modules interact
with that software.  Although that documentation is not required reading
before looking at any of the other documentation, it is B<highly recommended>
that you do.

=head1 BASIC DISTRIBUTION

The following modules are part of the distribution:

 NexTrieve			base module
 NexTrieve::Collection		logical collection object	
 NexTrieve::Collection::Index	logical index object within a collection
 NexTrieve::Daemon		logical daemon object
 NexTrieve::DBI			convert DBI statement to document sequence
 NexTrieve::Docseq		logical document sequence for indexing
 NexTrieve::Document		logical document object
 NexTrieve::Hitlist		result of query from search engine
 NexTrieve::Hitlist::Hit	a single hit of the result
 NexTrieve::HTML		convert HTML-file(s) to logical document(s)
 NexTrieve::Index		create an index out of a docseq
 NexTrieve::Mbox		convert Unix mailbox to document sequence
 NexTrieve::Message		convert Mail::Message object(s) to document(s)
 NexTrieve::MIME		MIME-type conversions for documents
 NexTrieve::Overview            an overview of NexTrieve and its Perl support
 NexTrieve::PDF                 convert PDF-files(s) to logical document(s)
 NexTrieve::Query		create/adapt query
 NexTrieve::Querylog		turn query log into Query objects
 NexTrieve::Replay		turn Querylog into Hitlist for a Search
 NexTrieve::Resource		create/adapt resource-file
 NexTrieve::RFC822		convert message(s) to logical document(s)
 NexTrieve::Search		logical search engine object
 NexTrieve::Targz		maintain a Targz message archive
 NexTrieve::UTF8		change encoding to UTF-8

The following scripts are part of the distribution:

 docseq		create a document sequence out of ready-made XML-files
 dbi2ntvml	convert SQL statement to a document sequence using DBI
 html2ntvml	convert one or more HTML-files to a document sequence
 mailbox2ntvml	convert one or more Unix mailboxes to a document sequence
 pdf2ntvml	convert one or more PDF-files to a document sequence
 targz_collect  collect new messages into Targz archive(s)
 targz_count	count number of messages in Targz archive(s)

=head1 SELECTIVE SUBMODULE LOADING

Not all of the NexTrieve submodules may be needed in a particular situation.
In order to save CPU and memory, you can easily load only the necessary
submodules, by specifying their names in the -use- statement with which
you load this module. E.g.,

 use NexTrieve;    or    use NexTrieve qw(:all);

will load B<all> submodules of NexTrieve (which may become more over the course
of time).  If you would only like to use the NexTrieve::Query and the
NexTrieve::Hitlist submodules, you can specify this as:

 use NexTrieve qw(Query Hitlist);

This can e.g. be handy if you only want to use the Query and Hitlist features.

=head1 SETUP METHODS

The following methods are available for setting up the NexTrieve object itself.

=head2 new

 $ntv = NexTrieve->new( {method => value} );

The creation of the NexTrieve object itself is done by calling the class method
"new" on the NexTrieve package.  The "new" class method accepts one input
parameter: a reference to a hash or list of method-value pairs as handled by
the L<Set> method.

=head1 DO-IT-YOURSELF METHODS

The following methods are available for those cases where you want to access
the results a NexTrieve query from a running NexTrieve server directly.

=head2 ask_server_port

 $hitlistxml = $ntv->ask_server_port( server:port | port,$queryxml );

Perform a NexTrieve query on a NexTrieve Daemon running on the specified
server and port.  Defaults to querying "localhost" if no server is specified.
The Query XML has to be in the format as described on:
http://www.nextrieve.com/usermanual/2.0.0/ntvqueryxml.stm .  Returns XML in
the format as described on:
http://www.nextrieve.com/usermanual/2.0.0/ntvhitlistxml.stm .

=head2 ask_server_port_fh

 $ntv->ask_server_port_fh( server:port | port,$queryxml,$handle );

Same function as L<ask_server_port>, but instead of returning the Hitlist XML,
writes the Hitlist XML to the B<handle> specified by the third input parameter.

=head2 ask_server_port_file

 $ntv->ask_server_port_file( server:port | port,$queryxml,$filename );

Same function as L<ask_server_port>, but instead of returning the Hitlist XML,
writes the Hitlist XML to the B<file> specified by the third input parameter.

=head1 INHERITED METHODS

The following methods are inherited from the NexTrieve object whenever any of
the sub-objects are made.  This means that any setting in the NexTrieve object
of these methods, will automatically be activated in the sub-objects, that are
created B<after> calling any of these methods, in the same manner.

=head2 DefaultInputEncoding

 $encoding = $ntvobject->DefaultInputEncoding;
 $ntvobject->DefaultInputEncoding( $encoding );

Many sources of information that are converted to XML, more precisely to
NTVML, by this set of Perl modules, do not contain information about the type
of encoding the characters of that source are in.  In a lot of cases, 
especially email, a character encoding of "us-ascii" is indicated, even if
"extended ASCII characters" are present.  Conversion modules, such as the
NexTrieve::RFC822 and NexTrieve::HTML modules, need to make assumptions on
the character encoding if no encoding information is present.

By calling the "DefaultInputEncoding" method with a specific encoding name on
an object of the NexTrieve family of modules, you indicate the encoding that
should be assumed if no encoding information is present.

If you never call this method, a default input encoding of "ISO-8859-1" is
assumed.  In practice, this is the set that consists of "us-ascii" and
"extended ASCII characters", which is most commonly found in email and HTML.

=head2 NexTrievePath

 $NexTrievePath = $ntv->NexTrievePath;
 $ntv->NexTrievePath( '/usr/local/nextrieve/bin' ); # checks NTV_PATH=

Sometimes you want to try out something when the NexTrieve package itself is
not installed in the standard location.  You can do this by specifying the
NTV_PATH= environment variable externally.  Or you can do this by calling the
"NexTrievePath" method and specifying the directory in which the NexTrieve
executables are located.

The default for the NexTrievePath is "/usr/local/nextrieve/bin".  If that
doesn't exist, the highest numbered executable directory from
"/usr/local/nextrieve" will be used, e.g. "/usr/local/nextrieve/2.0.0".

=head2 NexTrieveVersion

 $NexTrieveVersion = $ntv->NexTrieveVersion;
 $ntv->NexTrieveVersion( '2.0.0' ); # short for /usr/local/nextrieve/2.0.0

When several versions of the NexTrieve executables are installed on your
system, it can be handy to differentiate between them by just specifying the
version number.  This is what the "NexTrieveVersion" method allows you to do:
if all versions of NexTrieve executables are installed from
"/usr/local/nextrieve", then you can indicate which version you would like to
use by just specifying the version number, e.g. "2.0.0".

=head2 PrintError

 $PrintError = $ntvobject->PrintError;
 $ntvobject->PrintError( true | false | 'cluck' );

Sometimes you want your program to let you immediately know when there is an
error.  You can do this by calling the "PrintError" method with a
true value.  Each time an error occurs, a warning will be printed to STDERR
informing you of the error that occurred.  Check out the L<RaiseError> method
for letting your program stop with execution immediately when an error has
occurred.  Check out the L<Errors> method when you want to examine errors
completely under program control.

As a special debugging feature, it is also possible to specify the keyword
'cluck'.  If specified, it attempts to load the standard Perl module "Carp".
If that is successful, then it sets the $SIG{__WARN__} handler to call the
"Carp::cluck" subroutine.  This causes a stack-trace to be shown to the
developer when a warning occurs, either from an internal error or because
anything else executes a -warn- statement.

=head2 RaiseError

 $RaiseError = $ntvobject->RaiseError;
 $ntvobject->RaiseError( true | false | 'confess' );

Sometimes you want to have a program stop as soon as something goes wrong.
By calling the "RaiseError" method with a true value, you are telling the
module to immediately stop the program with an error message as soon as
anything goes wrong.  Check out L<PrintError> to have each error
output a warning on STDERR instead.  Check out L<Errors> if you want to
examine for errors completely under your control.

As a special debugging feature, it is also possible to specify the keyword
'confess'.  If specified, it attempts to load the standard Perl module "Carp".
If that is successful, then it sets the $SIG{__DIE__} handler to call the
"Carp::confess" subroutine.  This causes a stack-trace to be shown to the
developer when an error occurs, either from an internal error or because
anything else executes a -die- statement.

=head2 Tmp

 $Tmp = $ntv->Tmp;
 $ntv->Tmp( '/tmp' ); # checks TMP=

Sometimes the NexTrieve family of modules need to create an external file for
its operation.  By default it checks the value of the TMP= environment
variable.  If that environment variable doesn't exist, the "/tmp" directory
is assumed.  Or you can call the "Tmp" method to indicate which directory
should be used to create temporary files.

=head1 OBJECT CREATION METHODS

The modules of the NexTrieve family do B<not> contain "new" methods that can
be called directly.  Instead, if you want to create e.g. an NexTrieve::HTML
object, you call the (instance) method "HTML" on an instantiated NexTrieve
object, e.g. "$html = $ntv->HTML;".

Here only the parameters for the object creation are documented.  Any
additional methods are documented in the documentation of the module itself.

=head2 Collection

 $collection = $ntv->Collection( path, | create );

Create a "NexTrieve::Collection" object for a collection such as defined by
the NexTrieve executables.  The first input parameter specifies the path to
the directory of the collection.  The second input parameter specifies a
flag indicating whether the path should be created if it doesn't exist
already.

=head2 Daemon

 $daemon = $ntv->Daemon( file | xml | $resource, | server:port | port, | {method => value} );

Create a "NexTrieve::Daemon" object for performing NexTrieve queries with
NexTrieve running as a server.

The first input parameter specifies the resources that should be used by this
daemon process: it can either be the name of a file containing the resource XML
specication, or the resource XML specification as a value, or an instantiated
NexTrieve::L<Resource> object.

The second (optional) input parameter specifies the host and port on which this
daemon process should run.  It can be either specified as a "server:port"
combination, or just a port number.  In the latter case, the "localhost" will
be assumed to be the server specification.

The third (optional) input parameter can be a reference to a hash or
list of method-value pairs as handled by the L<Set> method.

=head2 DBI

 $converter = $ntv->DBI( {method => value} );

Create a "NexTrieve::DBI" object for performing a conversion from DBI statement
handles to NexTrieve::L<Document> objects as part of a document sequence as
described in "http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

This object is extensively used by the "dbi2ntvml" script.  It is also
capable of creating L<Docseq> and L<Resource> objects.

=head2 Docseq

 $docseq = $ntv->Docseq( {method => value} );

Create a "NexTrieve::Docseq" object for creating a document sequence as
described in "http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

Please note that the L<DBI>, L<HTML>, L<Mbox>, L<Message>, L<PDF> and
L<RFC822> objects are also capable of creating NexTrieve::Docseq objects.

=head2 Document

 $document = $ntv->Document( {method => value} );

Create a "NexTrieve::Document" object for creating a document as part of
document sequence as described in
"http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

=head2 Hitlist

 $hitlist = $ntv->Hitlist( | file | xml );

Create a "NexTrieve::Hitlist" object.

The (optional) input parameter either specifies the name of a file containing
XML conforming to the format described on
"http://www.nextrieve.com/usermanual/2.0.0/ntvhitlistxml.stm", or XML in that
format as a value.

Please note that creating a Hitlist object in this manner is of little use:
a Hitlist object is usually created through the "Hitlist" method of the
NexTrieve::L<Search> object.

=head2 HTML

 $converter = $ntv->HTML( {method => value} );

Create a "NexTrieve::HTML" object for performing a conversion from HTML-files
to NexTrieve::L<Document> objects as part of a document sequence as described in
"http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

This object is extensively used by the "html2ntvml" script.  It is also
capable of creating L<Docseq> and L<Resource> objects.

=head2 Index

 $index = $ntv->Index( file | xml | $resource, | {method => value}, | @files );

Create a "NexTrieve::Index" object for performing the NexTrieve indexing
process as described on
"http://www.nextrieve.com/usermanual/2.0.0/ntvindex.stm".

The first input parameter specifies the resources that should be used in the
indexing process: it can either be the name of a file containing the resource
XML specication, or the resource XML specification as a value, or an
instantiated NexTrieve::L<Resource> object.

The second (optional) input parameter can be a reference to a hash or
list of method-value pairs as handled by the L<Set> method.

The other input parameters (if any) are interpreted as names of files that
contain pre-generated document sequences, as created by the NexTrieve::Docseq
object, that should be indexed immediately.

It is also capable of creating a basic L<Resource> object from the information
stored in a NexTrieve index.

=head2 Mbox

 $converter = $ntv->Mbox( {method => value} );

Create a "NexTrieve::Mbox" object for performing a conversion from messages
as defined by L<RFC822>, stored in a Unix mailbox, to NexTrieve::L<Document>
objects as part of a document sequence as described in
"http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method on the L<RFC822> object.

This object is extensively used by the "mailbox2ntvml" script.  It is also
capable of creating L<Docseq> objects.

=head2 Message

 $converter = $ntv->Message( {method => value} );

Create a "NexTrieve::Message" object for performing a conversion from
Mail::Message objects to NexTrieve::L<Document> objects as part of a document
sequence as described in
"http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

This object is usually used in conjunction with the Mail::Box object, which
is part of the Mail::Box package as available on CPAN.  It is also capable of
creating L<Docseq> and L<Resource> objects.

=head2 PDF

 $converter = $ntv->PDF( {method => value} );

Create a "NexTrieve::PDF" object for performing a conversion from PDF-files
to NexTrieve::L<Document> objects as part of a document sequence as described in
"http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

This object is extensively used by the "pdf2ntvml" script.  It is also
capable of creating L<Docseq> and L<Resource> objects.

=head2 Query

 $query = $ntv->Query( | file | xml , | {method => value} );

Create a "NexTrieve::Query" object for performing the NexTrieve queries as
as described on "http://www.nextrieve.com/usermanual/2.0.0/ntvqueryxml.stm".

The first (optional) input parameter specifies the XML that should be used in
the creation of the object: it can either be the name of a file containing the
query XML specication, or the query XML specification as a value.

The second (optional) input parameter can be a reference to a hash or
list of method-value pairs as handled by the L<Set> method.

Please note that the L<Querylog> object is also capable of creating
NexTrieve::Query objects.

=head2 Querylog

 $querylog = $ntv->Querylog( file );

Create a "NexTrieve::Querylog" object for inspecting the queries that have
been made to a NexTrieve server running as a L<Daemon>.

The input parameter specifies the name of the query logfile to be used for the
creation of the "NexTrie::Querylog" object.

Please note that the Querylog object can create L<Query> objects.

=head2 Replay

 $replay = $ntv->Replay( {method => value} );

Create a "NexTrieve::Replay" object for performing a number or queries and
obtaining their results as a number of L<Hitlist> objects.

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

=head2 Resource

 $resource = $ntv->Resource( | file | xml , | {method => value} );

Create a "NexTrieve::Resource" object for indicating the use of resources
as described on "http://www.nextrieve.com/usermanual/2.0.0/ntvresourcefile.stm".

The first (optional) input parameter specifies the XML that should be used in
the creation of the object: it can either be the name of a file containing the
resource XML specication, or the resource XML specification as a value.

The second (optional) input parameter can be a reference to a hash or
list of method-value pairs as handled by the L<Set> method.

Please note that the L<DBI>, L<HTML>, L<Mbox>, L<Message>, L<PDF> and
L<RFC822> objects are also capable of creating NexTrieve::Resource objects.

=head2 RFC822

 $converter = $ntv->RFC822( {method => value} );

Create a "NexTrieve::RFC822" object for performing a conversion from messages
in the format as described by RFC 822 to NexTrieve::L<Document> objects as
part of a document sequence as described in
"http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

This object is extensively used by the L<Mbox> object.

=head2 Search

 $search = $ntv->Search( | server:port | port | file | xml | $resource, | {method => value} );

Create a "NexTrieve::Search" object for performing queries on a NexTrieve
index.  Searches can either be done using an on-demand approach, as described
on "http://www.nextrieve.com/usermanual/2.0.0/ntvsearch.stm", or by using a
server process as described on
"http://www.nextrieve.com/usermanual/2.0.0/ntvsearchd.stm".

The first input parameter either specifies the server and port on which a
server process is running.  Or it specifies the resources that should be used
in the on-demand searching process: then it can either be the name of a file
containing the resource XML specication, or the resource XML specification as
a value, or an instantiated NexTrieve::L<Resource> object.

The second (optional) input parameter can be a reference to a hash or
list of method-value pairs as handled by the L<Set> method.

Please note that search results are returned as a L<Hitlist> object.

=head2 Targz

 $targz = $ntv->Targz( {method => value} );

Create a "NexTrieve::Targz" object for archiving and performing conversions
on messages as defined by L<RFC822>, either stored as seperate files or in
Unix mailboxes, to NexTrieve::L<Document> objects as part of a document
sequence as described in
"http://www.nextrieve.com/usermanual/2.0.0/ntvindexerxml.stm".

The (optional) input parameter can be a reference to a hash or list of
method-value pairs as handled by the L<Set> method.

This object is extensively used by the "targz_collect" and "targz_count"
scripts.

=head1 CONVENIENCE METHODS

The following methods are inheritable from the NexTrieve module.  They are
intended to make life easier for the developer, and are specifically intended
to be used within user scripts such as templates.

=head2 Get

 ($encoding,$xml) = $ntvobject->Get( qw(encoding xml) );
 $ntvobject->Get( qw(encoding xml) ); # sets global vars $encoding and $xml

Sometimes you want to obtain the values returned by many methods from the
same object.  The "Get" method allows you to do just that: you specify the
names of the methods to be executed on the object and the values from the
method calls (without parameters) are either returned in the same order, or
they are used to set global variables with the same name as the method.

If you are interested in calling multiple methods with parameters on the same
object, and you are B<not> interested in the return values, then you should
call the L<Set> method.

=head2 openfile

 $handle = $ntvobject->openfile( "filename","mode" );
 $handle = $ntvobject->openfile( "command |" ); # pipe to output from command
 return unless $handle;

The "openfile" method returns a handle for the file or pipe that can be used
to read from or print to.  The parameters are the same as the standard Perl
function "open()".  If an error occurs during opening of the file or pipe,
an error is added to the internal list of L<Errors> and an empty value is
returned.

=head2 Set

 $ntvobject->Set( {
  methodname1	=> $value1,
  methodname2	=> $value2,
  methodname2	=> [parameter1,parameter2],
 } );

It is often a hassle for the developer to call many methods to set parameters
on the same object.  To reduce this hassle, the "Set" method was developed.
Instead of doing:

 $nvobject->methodname1( $value1 );
 $nvobject->methodname2( $value2 );
 $nvobject->methodname2( $parameter1,$parameter2 );

you can do this in one go as specified above.

The "Set" method accepts either a reference to a hash (as specified by B<{ }>)
or a reference to a list (as specified by B<[ ]>).  The reference to hash
method is preferable if the order in which the methods are executed, is not
important.  If the order in which the methods are supposed to be excuted B<is>
important, then you should use the reference to a list method, e.g.:

 $ntvobject->Set( [
  methodname1	=> $value1,
  methodname2	=> [],	                    # no parameters to be passed
  methodname2	=> [parameter1,parameter2], # more than 1 parameter
 ] );

Please note that if there is one parameter to the method, you can specify it
directly.  If there are more than one parameter to be passed to the method,
then you must specify them as a reference to a list by putting them between
square brackets, i.e. "[" and "]".  If no parameters need to be passed to the
method, you can specify this as a reference to an empty list, i.e. "[]".

The "Set" method disregards any values that were returned by the methods.  If
you are interested in the values that are returned by multiple methods, you
can use the L<Get> method.

Please note that the "Set" method is used internally in almost all object
creation methods to allow you to immediately specify the options to be activated
for that object.

=head2 slurp

 $contents = $self->slurp( $handle, | true | false );

The "slurp" method reads all the data it can from the specified handle (the
first input parameter) and returns that data and closes the handle.  If you do
not want the handle to be closed, specify a true value as the second input
parameter.  See the L<splat> method for writing out a complete file.

Silently does not perform any operation if no valid handle is specified: thus
the first input parameter can be a call to the L<openfile> method without any
problems.

=head2 splat

 $self->splat( $handle, $contents, | true | false ) || die "did not splat\n";

The "splat" method writes the data, specified by the second input parameter,
to the handle, specified by the first input parameter, and closes the handle.
If you do not want the handle to be closed, specify a true value as the third
input parameter.  See the L<slurp> method for reading in a complete file.

Silently does not perform any operation if no valid handle is specified: thus
the first input parameter can be a call to the L<openfile> method without any
problems.

Returns true upon success.

=head1 XML METHODS

The following methods have to do with all of the objects that are directly
related to the XML representation used by NexTrieve.

=head2 ampersandize

 $ntvobject->ampersandize( $value1,$value2...$valueN );

The "ampersandize" method processes all of its input parameters in place. 
It converts the &, < and > characters to their XML entity version and removes
any characters that may be illegal in XML.  The values are assumed to B<not>
have any entities upon input.  See the L<normalize> method for a more elaborate
cleaning up that handles text that can already contain entities (such as HTML).

=head2 encoding

 $encoding = $ntvobject->encoding;
 $ntvobject->encoding( $encoding );

Each object in the NexTrieve family that can contain XML, also knows in which
encoding the XML is stored.  What that encoding is, can be determined by calling
the "encoding" method.  If you want the XML of an object to be a specific
(different) encoding, then you can call this method also.

If you want to change the encoding of any XML, check out the L<recode>
method.

=head2 filename

 $filename = $ntvobject->filename;
 $ntvobject->filename( filename );

Many modules in the NexTrieve family are able to have their objects
initialized from XML stored in a file.  This is usually specified at the
time of creation of the object.  Or you want the XML of an object to be
stored in a specific file: this is usually specified by a call to the
L<write_file> method.

Whenever an object is initialized from XML in a file, the name of the file
is remembered in the object so that it can be used as a default when calling
the L<write_file> method.  If you want that default to be different from the
original filename, or there was no filename to begin with, you can call the
"filename" method to set the filename to be used later.

=head2 md5

 $md5 = $ntvobject->md5;

The "md5" method returns a so-called MD5 signature for the XML in the object.
For this to work, the Digest::MD5 module must be available also, otherwise
an empty string is always returned.  See the documentation of the Digest::MD5
module for more information.

=head2 nopi

 $ntvobject->nopi( true | false );
 $nopi = $ntvobject->nopi;

XML is normally created with a so-called "processor instruction", indicating
the version of XML (so far always "1.0") and the encoding in which the XML was
created, e.g. '<?xml version="1.0" encoding="utf-8"?>'.  In some situations
you want the XML to be created without this processor instruction (e.g. when
it is to become part of a stream of XML: only one processor instruction at the
very beginning of an XML-stream is allowed).  You can achieve this by calling
the "nopi" method with a true value before the XML is generated.

=head2 normalize

 $ntvobject->normalize( $value1,$value2...$valueN );

The "normalize" method processes all of its input parameters in place. 
It converts the &, < and > characters and any entities such as &nbsp; to theiri
correctly (numbered) XML entity version such as &#160; and removes any
characters that may be illegal in XML.  The values are assumed to may contain
named entities upon input.  See the L<ampersandize> method for a less elaborate
cleaning up that handles text that does not contain entities.

=head2 read_fh

 open( $handle,file );
 $ntvobject->read_fh( $handle );
 close( $handle );

Set the XML of a NexTrieve object from XML read from an opened handle.

=head2 read_file

 $ntvobject->read_file( | file );

Set the XML of a NexTrieve object from XML stored in a file.  Assume the
filename as indicated by calling the L<filename> method previously if no
filename was specified.

=head2 read_string

 $ntvobject->read_string( xml );

Set the XML of a NexTrieve object from XML stored as a value in memory.

=head2 recode

 $xml = $ntvobject->recode( $object | to_encoding, | xml, | from_encoding );

Obtain a version of XML that is encoded in a different encoding.  The first
input parameter is the encoding "to" which should be encoded.  This can also
be an object of the NexTrieve family of modules: then the encoding of that
object will be used as the encoding to encode to.

The second input parameter is the XML to be converted: if it is omitted, the
XML of the object itself is assumed.

The third input parameter B<must> be specified if the second input parameter
is specified: it indicates the encoding in which the XML currently is encoded.
If it is not specified, the encoding of the object itself will be assumed.

To just change the encoding of the XML of an object, check out the L<encoding>
method.

=head2 version

 $version = $ntvobject->version;

In order to facilitate (conversions to) expansions of the current XML format
of NTVML, a version number is internally used.  There is currently only one
version of NTVML, namely "1.0".  So that string is always returned by the
"version" method so far.

=head2 write_fh

 open( $handle,">file" ); 
 $ntvobject->write_fh( $handle );
 close( $handle );

Write the XML of a NexTrieve object to an opened handle.

=head2 write_string

 $xml = $ntvobject->write_string;

Return the XML of a NexTrieve object.  See the L<xml> method for a more
intuitive way of doing this.

=head2 write_file

 $ntvobject->write_file( | file );

Write the XML of a NexTrieve object to a file.  Assume the filename as
indicated by calling the L<filename> method previously if no filename was
specified and the XML of the object was not previously obtained by a call to
the L<read_file> method.

=head2 xml

 $xml = $ntvobject->xml;
 $ntvobject->xml( $xml );
 $ntvobject->xml;            # output XML to STDERR as warning

The "xml" method is actually a wrapper around the L<read_string> and
L<write_string> methods.  It allows easy setting and obtaining the XML of a
NexTrieve object.

In order to facilitate debugging your programs, a special feature has been
added to the "xml" method.  If the "xml" method is called in a void context
B<without> specifying any new XML, the XML of the object is output as a warning
to STDERR.

=head1 DEBUGGING METHODS

=head2 Dump

 @info = $ntvobject->Dump;
 $ntvobject->Dump;          # Data::Dumper->Dump output on object as warning

The "Dump" method is a quick-and-dirty interface to the Data::Dumper standard
Perl module.  When it is invoked, it will attempt to load the Data::Dumper
module.  If that is successful, it will create a dump of the object.  If the
method is called in a void context, the dump will be printed as a warning to
STDERR.  Else it will be returned by the "Dump" method.

No action will be performed if the Data::Dumper module can not be loaded.

=head2 Errors

 if ($ntvobject->Errors) {     # does not remove errors in scalar context
 @error = $ntvobject->Errors;  # returns errors, removes them from object

If an error occurs in the NexTrieve family of modules, they are only reported
"internally" as information added to the object.  To find out whether there are
any errors, you can call the "Errors" method in scalar context: it will then
tell you how many errors there are.  To find out what the errors exactly are,
you can call the "Errors" method in list context: this then also has the
side-effect of removing the error information from the object, effectively
resetting the error history of the object.

If you want your program to stop as soon as an error occurs, call the
L<RaiseError> method beforehand.  If you want your program to also output a
warning to STDERR each time an error occurs, call the L<PrintError>
method beforehand.

=head2 xmllint

 $ntvobject->xmllint( true | false );
 $xmllint = $ntvobject->xmllint;

The "xmllint" method is for the really paranoid of mind and for those who are
debugging their programs or additional modules to the NexTrieve family.  When
called with a true value, it will check for the availability of the "xmllint"
program of the "libxml2" package (as found on "http://www.xmlsoft.org").  If
it is found, it will set the "xmllint" flag in the object to "1".  Then,
anytime XML is generated by the object, the "xmllint" program will be called
to check the validity of the generated XML.  An error will be added to the
object (accessible to the L<Errors> method) with the output of the xmllint
program if any errors were found.

If the "xmllint" program is not found, then the flag in the object will remain
false and no additional checks will be performed when XML is generated.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 1995-2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.nextrieve.com and the other NexTrieve::xxx modules.

=cut
