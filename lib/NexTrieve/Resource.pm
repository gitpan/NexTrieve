package NexTrieve::Resource;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Resource::ISA = qw(NexTrieve);
$NexTrieve::Resource::VERSION = '0.30';

# Initialize the list of attribute keys
# Initialize the list of texttype keys
# Initialize the list of indexing keys

my @attributekey = qw(type key nvals);
my @texttypekey = qw(weight);
my @indexingkey = qw(logaction indexaction);

# Initialize the hash with references to all keys

my %allkey = (
 attribute	=> \@attributekey,
 texttype	=> \@texttypekey,
 indexing	=> \@indexingkey,
);

# Return true value for use

1;

#------------------------------------------------------------------------

# Following subroutines are for setting and retrieving field values

#------------------------------------------------------------------------

#  IN: 1 new value (default: no change)
# OUT: 1 current/old value

sub cache {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml(
   ref(shift),
   'cache',
   ['size'],
   @_
  );
} #cache

#------------------------------------------------------------------------

#  IN: 1 new value (default: no change)
# OUT: 1 current/old value

sub indexdir {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml(
   ref(shift),
   'indexdir',
   ['name'],
   @_
  );
} #indexdir

#------------------------------------------------------------------------

#  IN: 1 new value (default: no change)
# OUT: 1 current/old value

sub licencefile { goto &licensefile } #licencefile
sub licensefile {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml(
   ref(shift),
   'licensefile',
   ['name'],
   @_
  );
} #licensefile

#------------------------------------------------------------------------

#  IN: 1 new value (default: no change)
# OUT: 1 current/old value

sub logfile {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml(
   ref(shift),
   'logfile',
   ['name'],
   @_
  );
} #logfile

#------------------------------------------------------------------------

# the following methods apply to the <indexcreation> section

#------------------------------------------------------------------------

#  IN: 1 name of attribute
#      2 type of attribute (string,number,flag)
#      3 key type (key-unique,key-duplicates)
#      4 nvals value (1 or *)
# OUT: 1 current/old type of attribute
#      2 current/old type of key
#      3 current/old nvals value

sub attribute {

# Set and/or return the values

  return $_[0]->_field_variable_hash_kill_xml(
   ref(shift).'::attributes',
   shift,
   \@attributekey,
   @_
  );
} #attribute

#------------------------------------------------------------------------

#  IN: 1..N all attributes (name or list ref or hash ref)
# OUT: 1..N list of all attributes, each element list ref [name,type,key,nvals]

sub attributes {

# Set and/or return the values

  return $_[0]->_all_field_variable_hash_kill_xml(
   ref(shift).'::attributes',
   \@attributekey,
   @_
  );
} #attributes

#------------------------------------------------------------------------

#  IN: 1 new accentaction value
# OUT: 1 current/old accentaction

sub exact {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Indexcreation',
   'exact',
   [qw(accentaction)],
   @_
  );
} #exact

#------------------------------------------------------------------------

#  IN: 1 new accentaction value
# OUT: 1 current/old accentaction

sub fuzzy {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Indexcreation',
   'fuzzy',
   [qw(accentaction)],
   @_
  );
} #fuzzy

#------------------------------------------------------------------------

#  IN: 1 name of texttype
#      2 weight of texttype
# OUT: 1 current/old weight of texttype

sub texttype {

# Set and/or return the values

  return $_[0]->_field_variable_hash_kill_xml(
   ref(shift).'::texttypes',
   shift,
   \@texttypekey,
   @_
  );
} #texttype

#------------------------------------------------------------------------

#  IN: 1..N all texttypes (name or list ref or hash ref)
# OUT: 1..N list of all texttypes, each element list ref [name,weight]

sub texttypes {

# Set and/or return the values

  return $_[0]->_all_field_variable_hash_kill_xml(
   ref(shift).'::texttypes',
   \@texttypekey,
   @_
  );
} #texttypes

#------------------------------------------------------------------------

#  IN: 1 new classfile value
#      2 new foldfile value
#      3 new decompfile value
# OUT: 1 current/old classfile value
#      2 current/old foldfile value
#      3 current/old decompfile value

sub utf8data {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Indexcreation',
   'utf8data',
   [qw(classfile foldfile decompfile)],
   @_
  );
} #utf8data

#------------------------------------------------------------------------

# The following methods apply to the <indexing> section

#------------------------------------------------------------------------

#  IN: 1 new logaction value
# OUT: 1 current/old logaction value

sub nestedattrs {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Indexing',
   'nestedattrs',
   \@indexingkey,
   @_
  );
} #nestedattrs

#------------------------------------------------------------------------

#  IN: 1 new logaction value
#      2 new indexaction calue
# OUT: 1 current/old logaction value
#      2 current/old indexaction value

sub nestedtext {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Indexing',
   'nestedtext',
   \@indexingkey,
   @_
  );
} #nestedtext

#------------------------------------------------------------------------

#  IN: 1 new logaction value
# OUT: 1 current/old logaction value

sub unknownattrs {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Indexing',
   'unknownattrs',
   \@indexingkey,
   @_
  );
} #unknownattrs

#------------------------------------------------------------------------

#  IN: 1 new logaction value
#      2 new indexaction calue
# OUT: 1 current/old logaction value
#      2 current/old indexaction value

sub unknowntext {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Indexing',
   'unknowntext',
   [qw(logaction indexaction)],
   @_
  );
} #unknowntext

#------------------------------------------------------------------------

# The following methods apply to the <searching> section

#------------------------------------------------------------------------

#  IN: 1 new highlight name
#      2 new on text
#      3 new off text
# OUT: 1 current/old highlight name
#      2 current/old on text
#      3 current/old off text

sub highlight {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Searching',
   'highlight',
   [qw(name on off)],
   @_
  );
} #highlight

#------------------------------------------------------------------------

#  IN: 1 new querylog value
# OUT: 1 current/old querylog value

sub querylog {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Searching',
   'querylog',
   ['path'],
   @_
  );
} #querylog

#------------------------------------------------------------------------

#  IN: 1 new connector amount
#      2 new worker amount
#      3 new core amount
# OUT: 1 current/old connector amount
#      2 current/old worker amount
#      3 current/old core amount

sub threads {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml (
   ref(shift).'::Searching',
   'threads',
   [qw(connector worker core)],
   @_
  );
} #threads

#------------------------------------------------------------------------

# Following subroutines are for internal use only

#------------------------------------------------------------------------

sub _delete_dom {

# Obtain the object
# Obtain the class of the object

  my $self = shift;
  my $class = ref($self);

# For all of the fields that are used in this dom
#  Remove it

  foreach ('',qw(
   ::attributes
   ::encoding
   ::Indexcreation
   ::Indexing
   ::Searching
   ::texttypes
   ::version
    )) {
    delete( $self->{$class.$_} );
  }
} #_delete_dom

#------------------------------------------------------------------------

sub _create_dom {

# Obtain the object
# Obtain the class of the object
# Return now if there is a DOM already

  my $self = shift;
  my $class = ref($self);
  return if exists $self->{$class.'::version'};

# Initialize the version and the XML
# If there is XML
#  Obtain the encoding and the XML to work with
#  Save the version
#  Return now if no version information found

  my $version; my $xml = $self->{$class.'::xml'} || '';
  if ($xml) {
    $self->{$class.'::encoding'} = $self->_encoding_from_xml( \$xml );
    $version = $self->_version_from_xml( \$xml,'ntv:resource' );
    return unless $version;

# Else (no XML to be processed)
#  Set the version to indicate we have a DOM
#  And return

  } else {
    $self->{$class.'::version'} = $self->NexTrieve->version;
    return;
  }

# If it is the initial version
#  Obtain the index creation section
#  For both the attributes and the texttypes
#   Set the values
#  Set the other variables

  if ($version eq '1.0') {
    my $indexcreationxml = $1
     if $xml =~ s#<indexcreation>(.*)</indexcreation>##s;
    foreach my $type (qw(attribute texttype)) {
      ($self->{$class.'::'.$type.'s'},$indexcreationxml) =
       $self->_emptycontainers2namehash( $indexcreationxml,$type );
    }
    $self->{$class.'::Indexcreation'} =
     $self->_emptycontainers2hash( $indexcreationxml );

#  For al the sections that we need to process
#   Obtain that section of the XML
#   Create the name of the module
#   Set the parameters
  
    foreach my $section (qw(indexing searching ultralite)) {
      my $partxml = $1 if $xml =~ s#<$section>(.*)</$section>##s;
      my $module = $class.'::'.ucfirst($section);
      $self->{$module} = $self->_emptycontainers2hash($partxml);
    }

#  Set the parameters of the rest of the XML

    $self->{$class} = $self->_emptycontainers2hash( $xml );

# Else (unsupported version)
#  Make sure there is no version information anymore
#  Set error value and return

  } else {
    delete( $self->{$class.'::version'} );
    $self->_add_error( "Unsupported version of <ntv:resource>: $version" );
    return;
  }

# Save the version information

  $self->{$class.'::version'} = $version;
} #_create_dom

#------------------------------------------------------------------------

# OUT: 1 <ntv:resource> XML

sub _create_xml {

# Obtain the object
# Make sure we have a DOM

  my $self = shift;
  $self->_create_dom;

# Obtain the class definition to be used
# Obtain the version information and initial XML
# Return now if there was an error

  my $class = ref($self);
  my ($version,$xml) = $self->_init_xml;
  return unless $version;

# Add the initial container
# If it is version 1.0
#  Add the empty top containers

  $xml .= $self->_init_container( 'resource' );
  if ($version eq '1.0') {
    $xml .= $self->_hash2emptycontainers( $self->{$class} ) || '';

#  Add the <indexcreation> containers (if any)

    my $indexcreation;
    foreach my $type (qw(attribute texttype)) {
      $indexcreation .= $self->_namehash2emptycontainers(
       $self->{$class.'::'.$type.'s'},
       $type,
       $allkey{$type},
      ) || '' if exists $self->{$class.'::'.$type.'s'};
    }
    $indexcreation .= $self->_hash2emptycontainers( $self->{$class.'::Indexcreation'} ) || '';
    $xml .= <<EOD if $indexcreation;
<indexcreation>
$indexcreation</indexcreation>
EOD

#  For all of the group containers
#   Create the name of the field
#   Reloop if there is no info for it

    foreach (qw(indexing searching ultralite)) {
      my $name = $class.'::'.ucfirst($_);
      next unless keys %{$self->{$name}};

#   Add the containers in here

      $xml .= <<EOD;
<$_>
EOD
      $xml .= $self->_hash2emptycontainers( $self->{$name},$allkey{$_} || '' ) || '';
      $xml .= <<EOD;
</$_>
EOD
    }
  }

# Add the final part
# Return the complete XML, saving it in the object on the fly

  $xml .= <<EOD;
</ntv:resource>
EOD
  return $self->{$class.'::xml'} = $xml;
} #_create_xml

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Resource - handle the resource specifications of NexTrieve

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = new NexTrieve( | {method => value} );

 # using collections
 $collection = $ntv->Collection( path );
 $resource = $collection->Resource( mnemonic );

 # direct resource file access without using collections
 $resource = $ntv->Resource( | file | xml | {method => value} );

=head1 DESCRIPTION

The Resource object of the Perl support for NexTrieve.  Do not create
directly, but through the Resource method of the NexTrieve::Collection or
the NexTrieve object.

=head1 BASE METHODS

The following methods handle certain base aspects of the NexTrieve
resource-file.

=head2 cache

 $resource->cache( size ); 
 $cache = $resource->cache;

The "cache" method specifies the amount of RAM that will be used by the
NexTrieve programs as a data-cache.  If no postfix is specified, the amount
specified is assumed to be in bytes.  The following postfixes are recognized:

 "K"
Assume cache size is specified in Kilobytes

 "M"
Assume cache size is specified in Megabytes

 "G"
Assume cache size is specified in Gigabytes

By default, a value of "10M" is assumed, which is rather on the conservative
side.  Performance of any of the NexTrieve programs will generally improve
with a higher value specified, as long as the amount specified is less than
the amount of physical RAM available.

=head2 indexdir

 $resource->indexdir( path ); 
 $indexdir = $resource->indexdir;

The "indexdir" method specifies the name of the directory in which the
NexTrieve "ntvindex" program (as accessed by the NexTrieve::Index module) will
store its data-files, and which is used by the NexTrieve "ntvsearch" program
(as accessed by the NexTrieve::Search module) or the NexTrieve "ntvsearchd"
program (as started by the NexTrieve::Daemon module) to perform their searches
from.

=head2 licensefile

 $resource->licensefile( file ); 
 $licensefile = $resource->licensefile;

The "licensefile" method specifies the path of the file in which the NexTrieve
license keys are stored.   By default "/usr/local/nextrieve/license" is assumed
to be the location of the NexTrieve license file.

=head2 logfile

 $resource->logfile( file ); 
 $logfile = $resource->logfile;

The "logfile" method specifies the path of the file in which the NexTrieve
prigrams store their (error) messages.  By default B<no> logfile is assumed:
the NexTrieve programs will only send their messages to STDERR.

=head1 INDEXCREATION METHODS

The following methods apply to the <indexcreation> section of the so-called
NexTrieve resource-file.  These values are generally only used once during the
initial indexing process that sets up the internal data-structurs of a
NexTrieve index, as performed by the NexTrieve "ntvindex" program (accessible
with the NexTrieve::Index module).

=head2 attribute

 ($type,$key,$nvals) = $resource->attribute( name );
 $resource->attribute( name,
                      string | number | flag,
                      key-unique | key-duplicates | notkey,
                      1 | * );

The "attribute" method specifies the characteristics of a single attribute
of the XML to be indexed by NexTrieve.

The first input parameter specifies the "name" of the attribute.

The second input parameter specifies the "type" of the attribute.  Currently
three types of attributes are supported:

 "flag"
A binary flag which is either on (1) or off (0).

 "number"
An unsigned number between 0 and 2147483647 inclusive.

 "string"
Any string of characters.

The third input parameter specifies whether the attribute is supposed to be
a "key" or not.  If an attribute is considered to be "key", then multiple
references of the same value will only occupy a single piece of memory,
thereby reducing the memory requirements of NexTrieve programs significantly.

Currently three settings are supported:

 "key-unique"
If an attribute is marked as "key-unique", then only B<one> document can
exist in the index that contains a specific value for that attribute.  If
during indexing another document is encountered that has the same value for
an attribute marked "key-unique", then the original document will be marked
as "deleted".

 "key-duplicates"
If an attribute is marked as "key-duplicates", then B<more> than one document
can contain a specific value for that attribute.  Only the memory-saving
feature of keys are then in effect.

 "notkey"
If an attribute is marked as "notkey", then no attempt is made to save memory
for the value of the attribute.

The fourth attribute specifies the "multiplicity" of the attribute.  This
indicates whether an attribute can only have one value associated with it,
or whether it can have multiple values associated with it.  The following two
settings are currently supported:

 "1"
Only one value can be associated with this attribute.  If the value is omitted,
0 is assumed for "flag" and "numeric" type attributes and the empty string is
assumed for "string" type attributes.

 "*"
Any number of values can be associated with this attribute.  If no values
are specified for this attribute, it means just that: that there are no
values specified for this attribute.

It should be noted that more features may be added to attributes in the future.
Please check this space for any additions.

=head2 attributes

 @attribute = $resource->attributes;
 $resource->attributes( [name1,type1,key1,nvals1], [name2..] .. [nameN..] )

The "attributes" method allows you to specify B<all> attributes that should
be associated with a document.  Each input parameter specifies the specifics
of one attribute as a reference to a list in which the parameters have the
same order as the L<attribute> method.

=head2 texttype

 ($weight) = $resource->texttype( name );
 $resource->texttype( name,weight );

The "texttype" method specifies the characteristics of a single texttype
of the XML to be indexed by NexTrieve.

The first input parameter specifies the "name" of the texttype.

The second input parameter specifies the default "weight" of the texttype.
The weight of a texttype used in queries, can be overridden in the XML of the
query, as accessed or generated by the NexTrieve::Query module.  A default of
"100" will be assumed if no default weight is specified.

=head2 texttypes

 @texttype = $resource->texttypes;
 $resource->texttypes( [name1,weight1], [name2..] .. [nameN..] );

The "texttypes" method allows you to specify B<all> texttypes that should
be associated with a document.  Each input parameter specifies the specifics
of one texttype as a reference to a list in which the parameters have the
same order as the L<texttype> method.

=head1 INDEXING METHODS

The following methods apply to the <indexing> section of the so-called
NexTrieve resource-file.  These values are used during each indexing of a
NexTrieve index, as performed by the NexTrieve "ntvindex" program (accessible
with the NexTrieve::Index module).

=head2 nestedattrs

 $resource->nestedattrs( log | !log | stop );
 $logaction = $resource->nestedattrs;

The "nestedattrs" method indicates the action that should be performed if,
during indexing, an XML container is found B<inside> the container of a
an attribute.

The input parameter specifies what logging action should be performed if this
occurs.  There are currently 3 settings supported:

 "log"
Simply log the error to STDERR or the L<logfile> and continue indexing.

 "!log"
Do B<not> log the error but continue indexing.

 "stop"
Log the action to STDERR or the L<logfile> and B<stop> indexing.  This setting
is assumed if method "nestedattrs" is never called.

Please note that the contents of any nested containers will B<never> be added
to the NexTrieve data-structures.

=head2 nestedtext

 $resource->nestedtext( log | !log | stop, ignore | inherit );
 ($logaction,$indexaction) = $resource->nestedtext;

The "nestedtext" method indicates the actions that should be performed if,
during indexing, an XML container is found B<inside> the container of a
known texttype.

The first input parameter specifies what logging action should be performed.
There are currently 3 settings supported:

 "log"
Simply log the error to STDERR or the L<logfile> and continue indexing.  The
value of the second input parameter is significant.

 "!log"
Do B<not> log the error but continue indexing.  The value of the second input
parameter is significant.

 "stop"
Log the action to STDERR or the L<logfile> and B<stop> indexing.  The value of
the second input parameter is B<not> significant.  This setting is assumed if
method "nestedtext" is never called.

The second input parameter specifies what to do with the text inside the
container of an unknown texttype.  Currently, two settings are supported:

 "ignore"
Ignore the text in the container completely.

 "inherit"
Assume the texttype of the container in which the nested container was found.

=head2 unknownattrs

 $resource->unknownattrs( log | !log | stop );
 $logaction = $resource->unknownattrs;

The "unknownattrs" method indicates the actions that should be performed if,
during indexing, an XML container is found inside the container of an
attribute.

The input parameter specifies what logging action should be performed.  There
are currently 3 settings supported:

 "log"
Simply log the error to STDERR or the L<logfile> and continue indexing.

 "!log"
Do B<not> log the error but continue indexing.

 "stop"
Log the action to STDERR or the L<logfile> and B<stop> indexing. This setting
is assumed if the "unknownattrs" method is never called.

Please note that the contents of any unknown attribute containers will B<never>
be added to the NexTrieve data-structures.

=head2 unknowntext

 $resource->unknowntext( log | !log | stop, ignore | default );
 ($logaction,$indexaction) = $resource->unknowntext;

The "unknowntext" method indicates the actions that should be performed if,
during indexing, an XML container is found in the <text> container that is
B<not> known to have been specified as a valid texttype using either the
L<texttype> or L<texttypes> method.

The first input parameter specifies what logging action should be performed.
There are currently 3 settings supported:

 "log"
Simply log the error to STDERR or the L<logfile> and continue indexing.  The
value of the second input parameter is significant.

 "!log"
Do B<not> log the error but continue indexing.  The value of the second input
parameter is significant.

 "stop"
Log the action to STDERR or the L<logfile> and B<stop> indexing.  The value of
the second input parameter is B<not> significant.  This setting is assumed
if the "unknowntext" method is never called.

The second input parameter specifies what to do with the text inside the
container of an unknown texttype.  Currently, two settings are supported:

 "ignore"
Ignore the text in the container completely.

 "default"
Assume the "default" texttype for the text found in the container.

=head1 SEARCHING METHODS

The following methods apply to the <searching> section of the so-called
NexTrieve resource-file.  These values are used during the searching of a
NexTrieve index, as performed by the NexTrieve "ntvsearch" and "ntvsearchd"
programs (accessible with the NexTrieve::Search module).

=head2 highlight

 $resource->highlight( container,on,off );
 ($container,$on,$off) = $resource->highlight;

The "highlight" method specifies which strings should be used to indicate
highlighted words in the preview of a hit from a hitlist.

The first input parameter must be specified if you want an XML/HTML way of
specifying a highlighted word.  It specifies the name of the container (without
the surrounding < and >) in which a highlighted word should be placed.  By
default, the string 'b' is assumed, causing the <b>highlighted</b> container
to be used.

The second and third input parameter must be specified if you do not want to
use an XML/HTML way of specifying a highlighted word.  The second input
parameter then indicates the string that should be placed B<before> each
highlighted word and the third input parameter specifies the string to be
placed B<after> each highlighted word.

Please note that you should be careful to not specify anything as the second
and third input parameter that may result in invalid XML.  By specifying only
the first input parameter, you are ensured that the generated hitlist XML will
always be valid.

=head2 querylog

 $resource->querylog( directory );
 $querylogdirectory = $resource->querylog;

The "querylog" method specifies the B<directory> in which the "ntvsearchd"
NexTrieve program (as accessible by the NexTrieve::Daemon module) will create
a logfile for storing each query made with a timestamp.

A new logfile (whose name is constructed from the current date and time) will
be created each time the "ntvsearchd" program is started.

Queries will B<not> be logged if the "querylog" method is never called.

Queries from a query log file can be obtained with the NexTrieve::Querylog
module.

=head2 threads

 $resource->threads( connector,worker,core );
 ($connector,$worker,$core) = $resource->threads;

The "threads" method only applies to the "ntvsearchd" NexTrieve program and
is only applicable if "ntvsearchd" is available in a "threaded" form on your
platform.  Execute the "executable" method of the NexTrieve::Daemon object to
check this.

The first input parameter specifies the maximum number of simultaneous
connections that the search service is capable of handling.  A typical number
for this is "50".

The second input parameter specifies the maximum number of queries that can
be active simultaneously.  A number similar to the first input parameter is
advisable.

The third input parameter specifies the maximum number of simultaneous core
operations that can take place.  This is typically about 1/10th of the number
of simultaneous queries, as specified with the second input parameter.

=head1 ULTRALITE METHODS

The <ultralite> container of the NexTrieve resource-file is currently not
supported by the Perl modules.

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
