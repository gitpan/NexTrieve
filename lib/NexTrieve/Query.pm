package NexTrieve::Query;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Query::ISA = qw(NexTrieve);
$NexTrieve::Query::VERSION = '0.03';

# Initialize the list of texttype keys

my @texttypekey = qw(weight);

# Return true value for use

1;

#------------------------------------------------------------------------

#  IN: 1 new value for constraint
# OUT: 1 current/old value for constraint

sub constraint {
 shift->_single_value( qw(Containers constraint),@_ ) } #constraint

#------------------------------------------------------------------------

#  IN: 1 new value for displayed hits
# OUT: 1 current/old value for displayed hits

sub displayedhits {
 shift->_single_value( qw(Attributes displayedhits),@_ ) } #displayedhits

#------------------------------------------------------------------------

#  IN: 1 new value for firsthit
# OUT: 1 current/old value for firsthit

sub firsthit { shift->_single_value( qw(Attributes firsthit),@_ ) } #firsthit

#------------------------------------------------------------------------

#  IN: 1 new value for type
# OUT: 1 current/old value for type

sub fuzzylevel {
 shift->_single_value( qw(Attributes fuzzylevel),@_ ) } #fuzzylevel

#------------------------------------------------------------------------

#  IN: 1 new value for highlightlength
# OUT: 1 current/old value for highlightlength

sub highlightlength {
 shift->_single_value( qw(Attributes highlightlength),@_ ) } #highlightlength

#------------------------------------------------------------------------

#  IN: 1 new value for id
# OUT: 1 current/old value for id

sub id { shift->_single_value( qw(Attributes id),@_ ) } #id

#------------------------------------------------------------------------

#  IN: 1 new value for indexname
# OUT: 1 current/old value for indexname

sub indexname {
 shift->_single_value( qw(Containers indexname),@_ ) } #indexname

#------------------------------------------------------------------------

#  IN: 1 new value for lasthit
# OUT: 1 current/old value for lasthit

sub lasthit { shift->_single_value( qw(Attributes lasthit),@_ ) } #lasthit

#------------------------------------------------------------------------

#  IN: 1 new value for qall
# OUT: 1 current/old value for qall

sub qall { shift->_single_value( qw(Containers qall),@_ ) } #qall

#------------------------------------------------------------------------

#  IN: 1 new value for qany
# OUT: 1 current/old value for qany

sub qany { shift->_single_value( qw(Containers qany),@_ ) } #qany

#------------------------------------------------------------------------

#  IN: 1 new value for qnot
# OUT: 1 current/old value for qnot

sub qnot { shift->_single_value( qw(Containers qnot),@_ ) } #qnot

#------------------------------------------------------------------------

#  IN: 1 new value for query
# OUT: 1 current/old value for query

sub query { $_[0]->_variable_kill_xml( ref(shift),@_ ) } #query

#------------------------------------------------------------------------

#  IN: 1 new value for showattributes
# OUT: 1 current/old value for showattributes

sub showattributes {
 shift->_single_value( qw(Attributes showattributes),@_ ) } #showattributes

#------------------------------------------------------------------------

#  IN: 1 new value for showpreviews
# OUT: 1 current/old value for showpreviews

sub showpreviews {
 shift->_single_value( qw(Attributes showpreviews),@_ ) } #showpreviews

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

#  IN: 1 new value for totalhits
# OUT: 1 current/old value for totalhits

sub totalhits { shift->_single_value( qw(Attributes totalhits),@_ ) } #totalhits

#------------------------------------------------------------------------

#  IN: 1 new value for type
# OUT: 1 current/old value for type

sub type { shift->_single_value( qw(Attributes type),@_ ) } #type

#------------------------------------------------------------------------

# The following subroutines are for creating and deleting the dom

#------------------------------------------------------------------------

sub _delete_dom {

# Obtain the object
# Obtain the class of the object

  my $self = shift;
  my $class = ref($self);

# For all of the fields that are used in this dom
#  Remove it

  foreach ('',qw(
   ::Attributes
   ::encoding
   ::Containers
   ::texttypes
   ::version
    )) {
    delete( $self->{$class.$_} );
  }
} #_delete_dom

#------------------------------------------------------------------------

sub _create_dom {

# Obtain the object
# Save the class of the object
# Return now if there is a DOM already

  my $self = shift;
  my $class = ref($self);
  return if exists $self->{$class.'::version'};

# Initialize the version, xml and attributes
# If there is XML to be processed
#  Obtain the encoding and the XML to work with
#  Save the version and attributes
#  Return now if no version information found

  my ($version,$attributes); my $xml = $self->{$class.'::xml'} || '';
  if ($xml) {
    $self->{$class.'::encoding'} = $self->_encoding_from_xml( \$xml );
    ($version,$attributes) = $self->_version_from_xml( \$xml,'ntv:query' );
    return unless $version;

# Else (no XML to be processed)
#  Set the version to indicate we have a DOM
#  And return

  } else {
    $self->{$class.'::version'} = $self->NexTrieve->version;
    return;
  }

# If it is the initial version
#  Obtain the attributes
#  Obtain the containers
#  Obtain the query without surrounding whitespace
#  Save the query

  if ($version eq '1.0') {
    $self->{$class.'::Attributes'} = $self->_attributes2hash( $attributes );
    $self->{$class.'::Containers'} = $self->_containers2hash( $xml );
    $xml =~ s#^\s+##s; $xml =~ s#\s+$##s;
    $self->{$class} = $xml;

# Else (unsupported version)
#  Make sure there is no version information anymore
#  Set error value and return

  } else {
    delete( $self->{$class.'::version'} );
    $self->_add_error( "Unsupported version of <ntv:query>: $version" );
    return;
  }

# Save the version information

  $self->{$class.'::version'} = $version;
} #_create_dom

#------------------------------------------------------------------------

# OUT: 1 <ntv:query> XML

sub _create_xml {

# Obtain the object
# Make sure we have a DOM

  my $self = shift;
  $self->_create_dom;

# Obtain the class definition to be used
# Obtain the version information and initial XML
# Return now if an error has occurred

  my $class = ref($self);
  my ($version,$xml) = $self->_init_xml;
  return unless $version;

# If it is version 1.0
#  Create the attributes field name
#  Obtain a reference to the attribute section (create and save if not exists)
#  Make sure we _always_ use the long version of XML
#  If there is a lasthit specification
#   Make sure there is an equivalent displayedhits specification

  if ($version eq '1.0') {
    my $field = $class.'::Attributes';
    my $aref = $self->{$field} ||= {};
    $aref->{'longform'} = 1;
    if (exists( $aref->{'lasthit'} )) {
      $aref->{'displayedhits'} ||=
       $aref->{'lasthit'} - ($aref->{'firsthit'} || 1) + 1;
    }

#  Initialize highligh length attribute value
#  If there is a query and automatic highlightlength was specified
#   Initialize length
#   For all of the words in the query (!!!encoding issues here!!!)
#    Take maximum
#   Create the final highlight length value
#   And store it as an attribute

    my $highlightlength = '';
    if ($self->{$class} and
         exists $aref->{'highlightlength'} and
         !$aref->{'highlightlength'}) {
      my $length = 0;
      foreach( split( /\W+/,$self->{$class} ) ) {
        $length = length($_) if length($_) > $length;
      }
      $length = $length>5 ? 5 : $length-1;
      $highlightlength = qq( highlighlength="$length");

#  Elseif we have a specific highlightlength
#   Create attribute value

    } elsif (my $length = $aref->{'highlightlength'}) {
      $highlightlength = qq( highlightlength="$length");
    }

#  Add the start of the container

    $xml .= $self->_init_container(
     'query',
     $highlightlength.
     $self->_hash2attributes( $self->{$field},
      [qw(id
          displayedhits
          firsthit
          fuzzylength
          longform
          showattributes
          showpreviews
          textrate
          totalhits
          type
         )]
      )
     ) || '';

#  Add the containers

    my $cref = $self->{$class.'::Containers'} ||= {};
    foreach (qw(constraint indexname qall qany qnot)) {
      $xml .= qq(<$_>$cref->{$_}</$_>\n) if $cref->{$_};
    }

#  Add the texttypes

    $xml .= $self->_namehash2emptycontainers(
     $self->{$class.'::texttypes'},
     'texttype',
     \@texttypekey,
    ) || '';

#  Add the query itself

    $xml .= <<EOD if $self->{$class};
$self->{$class}
EOD
  }

# Add the final part
# Return the complete XML, saving the XML in the object on the fly

  $xml .= <<EOD;
</ntv:query>
EOD
  return $self->{$class.'::xml'} = $xml;
} #_create_xml

#------------------------------------------------------------------------

1;
__END__

=head1 NAME

NexTrieve::Query - handle the Query specifications of NexTrieve

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $query = $ntv->Query( | file | xml | {method => value} );

=head1 DESCRIPTION

The Query object of the Perl support for NexTrieve.  Do not create
directly, but through the Query method of the NexTrieve object.

=head1 METHODS

The following methods are available to the NexTrieve::Query object.

=head2 constraint

 $query->constraint( 'attr1 = 1 &amp; attr2 = 2' );
 $constraint = $query->constraint;

=head2 displayedhits

 $query->displayedhits( number );
 $displayedhits = $query->displayedhits;

=head2 firsthit

 $query->firsthit( ordinal );
 $firsthit = $query->firsthit;

=head2 fuzzylevel

 $query->fuzzylevel( 0 | 1 | 2 | 3 );
 $fuzzylevel = $query->fuzzylevel;

=head2 highlightlength

 $query->highlightlength( 0 | number );
 $highlightlength = $query->highlightlength;

=head2 id

 $query->id( id );
 $id = $query->id;

=head2 indexname

 $query->indexname( mnemonic );
 $indexname = $query->indexname;

=head2 lasthit

 $query->lasthit( $ordinal );
 $lasthit -> $query->lasthit;

=head2 qall

 $query->qall( qw(all of these words must occur) );
 $qall = $query->qall;

=head2 qany

 $query->qany( qw(all of these words may occur) );
 $qany = $query->qany;

=head2 qnot

 $query->qnot( qw(none of these words may occur) );
 $qnot = $query->qnot;

=head2 query

 $query->query( qw(+must may -maynot) );
 $queryspec = $query->query;

=head2 showattributes

 $query->showattributes( true | false );
 $showattributes = $query->showattributes;

=head2 showpreviews

 $query->showpreviews( true | false );
 $showpreviews = $query->showpreviews;

=head2 type

 $query->type( exact | fuzzy );
 $type = $query->type;

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
