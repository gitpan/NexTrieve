package NexTrieve::Resource;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Resource::ISA = qw(NexTrieve);
$NexTrieve::Resource::VERSION = '0.01';

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

sub basedir {

# Set and/or return the value

  return $_[0]->_field_variable_hash_kill_xml(
   ref(shift),
   'basedir',
   ['name'],
   @_
  );
} #basedir

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

 $resource = $collection->Resource( mnemonic ); 
 $resource = $ntv->Resource( | file | xml | {method => value} );

=head1 BASE METHODS

The following methods handle certain base aspects of the NexTrieve
resource-file.

=head2 basedir

 $resource->basedir( path ); 
 $basedir = $resource->basedir;

=head2 indexdir

 $resource->indexdir( path ); 
 $indexdir = $resource->indexdir;

=head2 cache

 $resource->cache( size ); 
 $cache = $resource->cache;

=head2 licensefile

 $resource->licensefile( file ); 
 $licensefile = $resource->licensefile;

=head2 logfile

 $resource->logfile( file ); 
 $logfile = $resource->logfile;

=head1 INDEXCREATION METHODS

The following methods apply to the <indexcreation> section.

=head2 attribute

 ($type,$key,$nvals) = $resource->attribute( name );
 $resource->attribute( name,
                      string | number | flag,
                      key-unique | key-duplicates | notkey,
                      1 | * );

=head2 attributes

 @attribute = $resource->attributes;
 $resource->attributes( name1 | [name1,type1,key1,nvals1], name2 .. nameN )

=head2 texttype

 ($weight) = $resource->texttype( name );
 $resource->texttype( name,weight );

=head2 texttypes

 @texttype = $resource->texttypes;
 $resource->texttypes( name1 | [name1,weight1], name2 .. nameN );

=head1 INDEXING METHODS

The following methods apply to the <indexing> section.

=head2 unknowntext

 $resource->unknowntext( log | !log | stop, ignore | default );
 ($logaction,$indexaction) = $resource->unknowntext;

=head2 nestedtext

 $resource->nestedtext( log | !log | stop, ignore | inherit );
 ($logaction,$indexaction) = $resource->nestedtext;

=head2 unknownattrs

 $resource->unknownattrs( log | !log | stop );
 $logaction = $resource->unknownattrs;

=head2 nestedattrs

 $resource->nestedattrs( log | !log | stop );
 $logaction = $resource->nestedattrs;

=head1 SEARCHING METHODS

The following methods apply to the <searching> section.

=head2 highlight

 $resource->highlight( container,on,off );
 ($container,$on,$off) = $resource->highlight;

=head2 querylog

 $resource->querylog( file );
 $querylog = $resource->querylog;

=head2 threads

 $resource->threads( connector,worker,core );
 ($connector,$worker,$core) = $resource->threads;

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
