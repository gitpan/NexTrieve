package NexTrieve::Query;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Query::ISA = qw(NexTrieve);
$NexTrieve::Query::VERSION = '0.31';

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

Please note that all methods described here are directly related to the
Query XML as described on
http://www.nextrieve.com/usermanual/2.0.0/ntvqueryxml.stm .  Any new feautures
of NexTrieve should probably be supported by these methods, as no filtering
is taking place before the Query XML is generated.

=head2 constraint

 $query->ampersandize( $constraint = 'attr1 = 1 & attr2 = 2' );
 $query->constraint( $constraint );
 $constraint = $query->constraint;

The "constraint" method allows you to specify the constraint that should be
applied to the list of documents that is going to be searched.  A full list
of constraint capabilities can be found on
http://www.nextrieve.com/usermanual/2.0.0/ntvqueryxml.stm .  Please make sure
that the constraint is valid XML, most notably by making sure that '&' is
expressed as '&amp;' and '<' is expressed as '&lt;'.  This can be achieved
by converting the query with the L<ampersandize> method that is inherited

=head2 displayedhits

 $query->displayedhits( number );
 $displayedhits = $query->displayedhits;

The "displayedhits" method sets the maximum number of hits that you want to
have returned to you.  It is an alternate way of using the L<lasthit> method.
If neither the L<lasthit> or the "displayedhits" method is called on the
object, the number of hits to be returned is determined by what was specified
by the L<totalhits> method.

=head2 firsthit

 $query->firsthit( ordinal );
 $firsthit = $query->firsthit;

The "firsthit" method allows you to specify the ordinal number of the first
hit that you want returned.  This is particularly useful when "paging" through
a result list.  Either call the L<lasthit> method to specify the ordinal
number of the last hit you want returned, or the L<displayedhits> method to
specify the maximum number of hits you want returned.

The value "1" is assumed if the L<firsthit> method is never called.

=head2 fuzzylevel

 $query->fuzzylevel( 0 | 1 | 2 | 3 );
 $fuzzylevel = $query->fuzzylevel;

The "fuzzylevel" method allows you to specify the fuzzyness of the search that
should be used.  It is only applicable if the value "fuzzy" was specified
with a call to method L<type>.

Currently only the values 0, 1, 2 and 3 are allowed.  By default, a value of
"1" is assumed if the "fuzzylevel" method is never called.

=head2 highlightlength

 $query->highlightlength( 0 | number );
 $highlightlength = $query->highlightlength;

The "highlightlength" method allows you to specify the number of characters
that should be in a word to have the word highlighted in the preview of a hit.
It is only applicable if the value "fuzzy" was specified with a call to method
L<type>.

The value "0" indicates an automatic length determination that uses the length
of the words specified in the L<query>, L<qany>, L<qall> and L<qnot> methods.

The value "3" is assumed if the "highlightlength" method is never called.

=head2 id

 $query->id( id );
 $id = $query->id;

The "id" method is of little use with the Perl modules: it is used by the
NexTrieve server to identify queries with results that are offered to the
server using a persistent connection.  Since the Perl modules always break
the connection after receiving a result, there is not much point in using
this feature.

The input parameter specifies a string that uniquely identifies this query.
If specified, the same string will be returned by the "id" method of the
NexTrieve::Hitlist object.

=head2 indexname

 $query->indexname( mnemonic );
 $indexname = $query->indexname;

The "indexname" method is only applicable when using a Caching Query Server,
as described on http://www.nextrieve.com/usermanual/2.0.0/ntvcached.stm .

The "indexname" method specifies the name of the logical index that should be
used for this query.  No logical index will be assumed if this method is never
called.

=head2 lasthit

 $query->lasthit( $ordinal );
 $lasthit -> $query->lasthit;

The "lasthit" method specifies the ordinal number of the last hit that you
want to have returned.  As such, it is an alternative way for using the
L<displayedhits> method.  The ordinal number of the last possible hit, as
specified with a call to the L<totalhits> method, will be assumed if this
method is never called.

=head2 qall

 $query->qall( qw(all of these words must occur) );
 $qall = $query->qall;

The "qall" method specifies a list of words that should B<all> occur in a
hit.  It is an alternative way to specifying words using the "+" prefix in
the L<query> method.

=head2 qany

 $query->qany( qw(all of these words may occur) );
 $qany = $query->qany;

The "qany" method specifies a list of words that may or may not occur in a
hit.  It is an alternative way to specifying words without any prefix in
the L<query> method.

=head2 qnot

 $query->qnot( qw(none of these words may occur) );
 $qnot = $query->qnot;

The "qnot" method specifies a list of words that should B<not> occur in a
hit.  It is an alternative way to specifying words using the "-" prefix in
the L<query> method.

=head2 query

 $query->query( qw(+must may -maynot) );
 $queryspec = $query->query;

The "query" method specifies the query for which a hitlist should be returned.
It can consist of just a bunch of words.  If an exact search is specified with
the L<type> method, then the words can be prefixed with:

 "+" to indicate a word that B<must> occur in a document

 "-" to indicate a word that must B<not> occur in a document

The "query" method is an alternative to calling the L<qall>, L<qany> or
L<qnot> methods.

=head2 showattributes

 $query->showattributes( true | false );
 $showattributes = $query->showattributes;

The "showattributes" method allows you to specify whether you want the
attributes associated with a document, to be returned with the hit.  By
default attributes are returned with the hit and can be obtained by the
"attributes" method of the NexTrieve::Hitlist::Hit object.

Please note that in the future it may become possible to indicate specific
attributes to be returned, which will change the meaning of the input
parameters.  It is therefore recommended to only use the values "0" and "1"
as parameters to this method, so that future versions of this method can
remain compatible.

=head2 showpreviews

 $query->showpreviews( true | false );
 $showpreviews = $query->showpreviews;

The "showpreviews" method allows you to specify whether you want a preview of
the text where the hit was found in a document, to be returned with the hit.
By default the preview is returned with the hit and can be obtained by the
"preview" method of the NexTrieve::Hitlist::Hit object.

=head2 texttype

 $query->texttype( name,weight );
 ($weight) = $query->texttype( name );

The "texttype" method specifies the weight that should be applied to text
found in the given text type name.

The first input parameter specifies the "name" of the texttype.

The second input parameter specifies the "weight" of the texttype that should
be used in the query.  A default of "100" will be assumed if no weight is
specified.

=head2 texttypes

 $resource->texttypes( [name1,weight1], [name2..] .. [nameN..] );
 @texttype = $resource->texttypes;

The "texttypes" method allows you to weight ot B<all> texttypes that have
to have a weight different from the default weight of "100".  Each input
parameter specifies the specifics of one texttype as a reference to a list
in which the parameters have the same order as the L<texttype> method.

=head2 totalhits

 $query->totalhits( number );
 $totalhits = $query->totalhits;

The "totalhits" method specifies how many hits should initially be considered
for inclusion in the hitlist.  A default of "1000" is assumed if this method
is never called.

The actual number of hits returned is determined by the L<firsthit> and
L<displayedhits> or L<lasthit> method.

=head2 type

 $query->type( exact | fuzzy );
 $type = $query->type;

The "type" method indicates which type of search should be performed.  By
default a "fuzzy" search will be performed if this method is never called.
Currently, there are two values that can be specified:

- exact 

Each word should occur exactly as specified in the document.

- fuzzy

A context sensitive pattern algorithm is used to search for hits.  Words do
not need to be spelled exactly, but exactly spelled words are favoured over
misspelt words.

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
