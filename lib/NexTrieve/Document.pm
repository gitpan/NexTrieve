package NexTrieve::Document;

# Set modules to inherit from
# Set version information
# Make sure we do everything by the book from now on

@ISA = qw(NexTrieve);
$VERSION = '0.40';
use strict;

# Satisfy -require-

1;

#------------------------------------------------------------------------

# The following methods add data to the object

#------------------------------------------------------------------------

#  IN: 1 name of attribute
#      2..N value of attributes

sub attribute { 

# Obtain the object
# Make sure all XML is removed
# Save this attribute

  my $self = shift;
  $self->_kill_xml;
  push( @{$self->{ref($self).'::attributes'}},[@_] );
} #attribute

#------------------------------------------------------------------------

#  IN: 1..N listref to all names and value(s)

sub attributes {

# Obtain the object
# Make sure all XML is removed
# Set this as all attributes

  my $self = shift;
  $self->_kill_xml;
  @{$self->{ref($self).'::attributes'}} = @_;
} #attributes

#------------------------------------------------------------------------

#  IN: 1 xml to be processed
# OUT: 1 object itself

sub read_string {

# Obtain the object
# Do whatever we normally do

  my $self = shift;
  $self->SUPER::read_string( @_ );

# Obtain the class
# If there is an xml processing instruction in the XML (removing it on the fly)
#  Set the encoding of the object if there is an encoding

  my $class = ref($self);
  if ($self->{$class.'::xml'} =~ s#^\s*<\?xml(.*?)\?>\n?##s) {
    $self->{$class.'::encoding'} = $1 if $1 =~ m#encoding="([^"]*)"#;
  }

# Return the object

  return $self;
} #read_string

#------------------------------------------------------------------------

#  IN: 1 name of texttype (optional if only 1 text value)
#      2..N (reference to) text to be added

sub text {

# Obtain the object
# Make sure all XML is removed
# Add this text

  my $self = shift;
  $self->_kill_xml;
  push( @{$self->{ref($self).'::texts'}},[@_] );
} #text

#------------------------------------------------------------------------

#  IN: 1..N listref to all texttype names and values

sub texts {

# Obtain the object
# Make sure all XML is removed
# Set this as _all_ text

  my $self = shift;
  $self->_kill_xml;
  @{$self->{ref($self).'::texts'}} = @_;
} #texts

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
#  Save the filename in the object
#  Obtain the encoding
#  Add the processor instruction
#  Return whatever is the result of reading the handle
# Add error and return object

  if (my $handle = $self->openfile( $filename,'>' )) {
    $self->{$class.'::filename'} = $filename;
    my $encoding = $self->encoding || $self->DefaultInputEncoding;
    print $handle qq(<?xml version="1.0" encoding="$encoding"?>\n);
    return $self->write_fh( $handle );
  }
  return $self->_add_error( "Could not write to file '$filename': $!" );
} #write_file

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
   ::texts
   ::version
    )) {
    delete( $self->{$class.$_} );
  }
} #_delete_dom

#------------------------------------------------------------------------

sub _create_dom {} #_create_dom

#------------------------------------------------------------------------

# OUT: 1 <document> XML

sub _create_xml {

# Obtain the object
# Obtain the class definition to be used
# Return now if we have XML already

  my $self = shift;
  my $class = ref($self);
  return $self->{$class.'::xml'} if $self->{$class.'::xml'};

# Set the encoding if there is none specified yet
# Initialize the XML

  $self->encoding( $self->DefaultInputEncoding ) unless $self->encoding;
  my $xml = "<document>\n";

# Set the field name to use
# If there are attributes specified
#  Start the attributes container
#  For all of the attributes specified
#   Obtain the name
#   For all of the values
#    Add container
#  Close the attributes container

  my $field = $class.'::attributes';
  if ($self->{$field} and @{$self->{$field}}) {
    $xml .= "<attributes>\n";
    foreach my $list (@{$self->{$field}}) {
      my $name = shift(@{$list});
      foreach my $value (@{$list}) {
        $xml .= "<$name>$value</$name>\n";
      }
    }
    $xml .= "</attributes>\n";
  }

# Set the field name to use
# If there are texts specified
#  Start the text container
#  For all of the texts specified
#   If there is a name
#    For all of the values
#     Add container
#   Else
#    For all of the values
#     Just add
#  Close the text container

  $field = $class.'::texts';
  if ($self->{$field} and @{$self->{$field}}) {
    $xml .= "<text>\n";
    foreach my $list (@{$self->{$field}}) {
      if (my $name = @{$list} > 1 ? shift(@{$list}) : '') {
        foreach my $value (@{$list}) {
          $xml .= ref($value) ?
           "<$name>$$value</$name>\n" : "<$name>$value</$name>\n";
        }
      } else {
        foreach my $value (@{$list}) {
          $xml .= ref($value) ? "$$value\n" : "$value\n";
        }
      }
    }
    $xml .= "</text>\n";
  }

# Close the document container or empy out completely if nothing in it
# Return the finished XML

  $xml = $xml eq "<document>\n" ? '' : "$xml</document>";
  return $self->{$class.'::xml'} = $xml;
} #_create_xml

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Document - create XML for indexing a single document

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = new NexTrieve( | {method => value} );
 $index = $ntv->Index( | filename | xml | $resource );

 $docseq = $index->Docseq( | encoding );
 $document = $ntv->Document( | {method => value} );
 $docseq->add( $document );

=head1 DESCRIPTION

The Document object of the Perl support for NexTrieve.  Do not create
directly, but through the Document method of the NexTrieve object.

 $document = $ntv->Document( | {method => value} );

Please note that many of the other modules have NexTrieve::Document object
creation routines of their own, usually called "Document".  So only if you
would like to get your hands dirty, creating NexTrieve::Document objects of
your own design, is when you actually use methods of this module directly.

=head1 METHODS

The following methods apply to the adding of attributes and text.

=head2 attribute

 $document->attribute( name,@value );

The "attribute" method adds one or more attributes with the same name to the
NexTrieve::Document object.  When the XML of the document object is serialized,
then each attribute container will be a descendant of the <attributes>
container of the document XML.

The strings that are stored as the values of the attribute, should already be
encoded in the same manner as the encoding of the document indicates.

The first input parameter specifies the name of the attribute.

The other input parameter specify values for which an attribute container with
the given name should be added.  Please note that if you specify more than one
value, the attribute B<must> be known in the NexTrieve resource-file with a
multiplicity of "*".

For example:

 $document->attribute( 'title','This is the title' );

will cause the following XML to be generated (if it was the only call):

 <attributes>
 <title>This is the title</title>
 </attributes>

Another example:

 $document->attribute( 'category',1,2,3,4 );

will cause the following XML to be generated (if it was the only call):

 <attributes>
 <category>1</category>
 <category>2</category>
 <category>3</category>
 <category>4</category>
 </attributes>

See the L<attributes> method for specifying B<all> attributes of a document at
the same time.

=head2 attributes

 $document->attributes( [name1,@value1], [name2,@value2] ... [nameN,@valueN] )

The "attributes" method adds B<all> attributes of a document at the same time.
The input parameters each should be a reference to a list.  Each of these
lists have the same input parameter sequence as a single call to method
L<attribute>: the first element specifies the name of the attribute, the other
elements specify values for which to create containers with the given name.

Please note that calling method "attributes" will throw away any other
attributes that have been previously specified with either a call to method
L<attribute> or "attributes".  So you typically only call method "attributes"
only once during the lifetime of an object.

=head2 text

 $document->text( text | name,@text );

The "text" method allows you to either add a basic text (to be placed in the
<text> container without container) or one or more named texttypes.

The strings that are stored as the values of the texttypes, should already be
encoded in the same manner as the encoding of the document indicates.

If only one input parameter is specified, it is assumed to be a text that is
to be added without container.

If more than one input parameter is specified, then the first input parameter
is the name of the texttype to serialize the text in.  In that case, all the
other input parameters indicate the values to be serialized in those containers.

For example:

 $document->text( 'This is the text' );

will cause the following XML to be generated (if it was the only call):

 <text>
 This is the text
 </attributes>

Another example:

 $document->text( 'p',qw(one two three four) );

will cause the following XML to be generated (if it was the only call):

 <text>
 <p>one</p>
 <p>two</p>
 <p>three</p>
 <p>four</p>
 </text>

See the L<texts> method for specifying B<all> text of a document at the same
time.

=head2 texts

 $document->texts( [text], [name1,@value1], ... [nameN,@valueN] );

The "texts" method adds B<all> text of a document at the same time.  The input
parameters each should be a reference to a list.  Each of these lists have the
same input parameter sequence as a single call to method L<text>: if there is
only one element, it is a text without container, else the first element
specifies the name of the texttype, the other elements specify values for which
to create containers with the given name.

Please note that calling method "texts" will throw away any other texts that
have been previously specified with either a call to method L<text> or "texts".
So you typically only call method "texts" only once during the lifetime of an
object.

=head2 xml

 $xml = $document->xml;
 $document->xml( $xml );

The "xml" method can be called on the NexTrieve::Document object, but is
B<different> from all the other "xml" methods that can be called on other
objects.

The XML returned by the NexTrieve::Document object B<never> contains an XML
processor instruction.  This is because the Nextrieve::Document object is
supposed to become part of a document sequence, in which the XML processor
instruction would cause problems.

This also means that, although you can save the NexTrieve::Document object
in a file, it is not wise to do so if the encoding of the object is different
from "UTF-8" (the default encoding assumed if there is no XML processor
instruction in an XML stream).

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
