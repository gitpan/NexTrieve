package NexTrieve::HTML;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::HTML::ISA = qw(NexTrieve);
$NexTrieve::HTML::VERSION = '0.03';

# Use other NexTrieve modules that we need always

use NexTrieve::Docseq ();
use NexTrieve::Document ();

# Create the list of displaycontainers for matching (no space around it)

my $displaycontainers = join( '|',qw(
 b
 em
 font
 i
 strike
 strong
 tt
 u
) );

# Create the list of containers of which the content will be removed

my $removecontainers = join( '|',qw(
 script
) );

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 Docseq object (optional)
#      2..N list of files to be processed
# OUT: 1 Docseq object

sub Docseq {

# Obtain the object
# Obtain the Docseq object if there is any, create new if none available

  my $self = shift;
  my $docseq = ref($_[0]) eq 'NexTrieve::Docseq' ?
   shift : $self->NexTrieve->Docseq;

# For all of the specified filenames
#  Add the document to the docseq
# Return the docseq object (in case it was new)

  foreach my $filename (@_) {
    my $document = $self->Document( $filename );
    $docseq->add( $self->Document( $filename ) );
  }
  return $docseq;
} #Docseq

#------------------------------------------------------------------------

#  IN: 1 filename or HTML
# OUT: 1 instantiated NexTrieve::Document object

sub Document {

# Obtain the object
# Obtain the NexTrieve object
# Obtain an empty Document object

  my $self = shift;
  my $ntv = $self->NexTrieve;
  my $document = $ntv->Document;

# Initialize the HTML
# Obtain the filename
# If it looks like the filename is actually HTML
#  Reset filename and use as HTML

  my $html = '';
  my $filename = shift;
  if ($filename =~ m#\n#s) {
    $html = $filename; $filename = '';

# Else (seems like a filename, try to open it)
#  Attempt to open the file
#  Return the document so far if failed
#  Obtain local copy of the HTML
#  And close the file

  } else {
    my $handle = $document->openfile( $filename );
    return $document unless $handle;
    $html = join( '',<$handle> );
    close( $handle );
  }

# Obtain the length to be processed
# Return now if there is nothing to do
# Get rid of any null bytes (if they're there, there of no use)

  my $length = length($html);
  return $document->_add_error( "No HTML to be processed" ) unless $length;
  $html =~ s#\0##sg;

# If we're supposed to do the binary file check
#  Calculate the number of ISO-8859-1 illegal characters
#  If we think they indicate a binary file
#   Put out an error and return

  if ($self->binarycheck) {
    my $count = $html =~ tr#\x00-\x08\x0b-\x0c\x0e-\x1a\x1c-\x1f##;
    if ($count > 100 or $count/$length > .01) {
      return $document->_add_error( "File '$filename' is probably binary" );
    }
  }

# Make sure all of the tags are in lowercase (simplifies further matching)
# Get rid of anything that looks like a comment

  $html =~ s#(</?\w+)#\L$1\E#sgi;
  $html =~ s#<!--.*?-->##sg;

# Obtain the name of the containers to be removed with their content
# Get rid of anything that looks like a script

  my $containers = $self->removecontainers || $removecontainers;
  $html =~ s#<script[^>]*>.*?</script>##sg;

# Obtain the meta tag for content-type, if any
# Obtain the content encoding (if any)
# Set the encoding of the document

  my $encoding =
   $html =~ m#(<meta[^>]+http-equiv="content-type"[^>]*>)#si ? $1 : '';
  $encoding = $encoding =~ m#content="text/html; charset=([^"]+)"#si ?
   $1 : $self->encoding || $ntv->encoding || '';
  $document->encoding( $encoding );

# Obtain the meta tag for description, if any
# Obtain the meta description (if any)
# Create XML version (if any)

  my $description =
   $html =~ m#(<meta[^>]+name="description"[^>]*>)#si ? $1 : '';
  $description = $description =~ m#content="([^"]+)"#si ? $1 : '';

# Obtain the meta tag for keywords, if any
# Obtain the meta keywords (if any)
# Create XML version (if any)

  my $keywords = $html =~ m#(<meta[^>]+name="keywords"[^>]*>)#si ? $1 : '';
  $keywords = $keywords =~ m#content="([^"]+)"#si ? $1 : '';
  
# Obtain the title (if any)
# Get rid of anything left in the head
# Get rid of HTML and BODY tags (rest should be "valid" html

  my $title = $html =~ s#<title[^>]*>(.*?)</title>##s ? $1 : '';
  $html =~ s#<head>.*?</head>##sgi;
  $html =~ s#</?(?:html|body)>##sgi;

# If there is html to process
#  Obtain the display containers
#  Throw away any displayable containers inside the html completely
#  Replace all other containers by a space

  if ($html) {
    $containers = $self->displaycontainers || $displaycontainers;
    $html =~ s#<($containers)\b[^>]*>(.*?)</\1>#$2#sg;
    $html =~ s#<[^<>]*># #sg;
  }

#  Normalize the text
#  Initialize the attribute version of the title
#  If there is a title to process
#   If there is a maximum length specified
#    Set the short version
#    Make sure there are no broken entities at the end
#   Else (no maximum specified)
#    Just copy the title

  $document->normalize( $title,$description,$keywords,$html );
  my $attributetitle = '';
  if ($title) {
    if (my $titlemax = $self->titlemax) {
      $attributetitle = substr($title,0,$titlemax);
      $attributetitle =~ s#&\#?\w*$##s;
    } else {
      $attributetitle = $title;
    }

# Create XML version of title
# Create XML version of attribute version of title

    $title = "<title>$title</title>\n" if $title;
    $attributetitle = "<title>$attributetitle</title>\n" if $attributetitle;
  }

# Containerize the filename if there is one
# Containerize the description if there is one
# Containerize the keywords if there are any

  $filename = "<filename>$filename</filename>\n" if $filename;
  $description = "<description>$description</description>\n" if $description;
  $keywords = "<keywords>$keywords</keywords>\n" if $keywords;

# Remove whitespace on the outside of the remaining text
# Set the XML in the document

  $html =~ s#^\s+##s; $html =~ s#\s+$##s;
  $document->{ref($document).'::xml'} = <<EOD;
<document>
<attributes>
$filename$attributetitle</attributes>
<text>
$title$description$keywords$html
</text>
</document>
EOD

# Return the document

  return $document;
} #Document

#------------------------------------------------------------------------

# Following methods change the object

#------------------------------------------------------------------------

# OUT: 1..N list with structures for $resource->attributes

sub attributes {

# Return the attributes specification

  return (
   [qw(filename string key-unique 1)],
   [qw(title string notkey 1)],
  );
} #attributes

#------------------------------------------------------------------------

#  IN: 1 new setting of "binary check" flag
# OUT: 1 current/old setting of "binary check" flag

sub binarycheck { shift->_class_variable( 'binarycheck',@_ ) } #binarycheck

#------------------------------------------------------------------------

#  IN: 1..N new display containers
# OUT: 1..N current/old display containers

sub displaycontainers { shift->_containers( 'display',@_ ) } #displaycontainers

#------------------------------------------------------------------------

#  IN: 1..N new remove containers
# OUT: 1..N current/old remove containers

sub removecontainers { shift->_containers( 'remove',@_ ) } #removecontainers

#------------------------------------------------------------------------

# OUT: 1..N list with structures for $resource->texttypes

sub texttypes { qw(description keywords title)
} #texttypes

#------------------------------------------------------------------------

#  IN: 1 new setting of maximum length of title as attribute
# OUT: 1 current/old setting of maximum length of title as attribute

sub titlemax { shift->_class_variable( 'titlemax',@_ ) } #titlemax

#------------------------------------------------------------------------

# Internal subroutines go here

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

__END__

=head1 NAME

NexTrieve::HTML - convert HTML to NexTrieve Document objects

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );

 $html = $ntv->HTML( | {method => value} );

 $index = $ntv->Index( $resource );
 $docseq = $index->Docseq;
 foreach my $file (<*.html>) {
   $docseq->add( $html->Document( $file ) );
 }
 $docseq->done;

=head1 DESCRIPTION

The HTML object of the Perl support for NexTrieve.  Do not create
directly, but through the HTML method of the NexTrieve object;

=head1 METHODS

These methods are available to the NexTrieve::HTML object.

=head2 Docseq

 $docseq = $html->Docseq( @file );

 $index = $ntv->Index( $resource );
 $html->Docseq( $index->Docseq,@file );

=head2 Document

 $document = $html->Document( file | html );

=head2 attributes

 $resource->attributes( $html->attributes );

=head2 binarycheck

 $html->binarycheck( true | false );
 $binarycheck = $html->binarycheck;

=head2 displaycontainers

 $html->displaycontainers( qw(b i u) );
 @displaycontainer= $html->displaycontainers;

=head2 encoding

 $html->encoding( 'encoding-name' );
 $defaultencoding = $html->encoding;

=head2 removecontainers

 $html->removecontainers( qw(script embed) );
 @removecontainer= $html->removecontainers;

=head2 texttypes

 $resource->texttypes( $html->texttypes );

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
