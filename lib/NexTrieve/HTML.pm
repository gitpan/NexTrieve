package NexTrieve::HTML;

# Set modules to inherit from
# Set version information
# Make sure we do everything by the book from now on

@ISA = qw(NexTrieve);
$VERSION = '0.40';
use strict;

# Use other NexTrieve modules that we need always

use NexTrieve::Docseq ();
use NexTrieve::Document ();

# Create the list of displaycontainers for matching (no space around it)
# Create the list of containers of which the content will be removed

my $displaycontainers = NexTrieve->_default_displaycontainers;
my $removecontainers = NexTrieve->_default_removecontainers;

# Satisfy -require-

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 filename or HTML
#      2 type of input specification ('', 'filename' or 'url')
# OUT: 1 instantiated NexTrieve::Document object

sub Document {

# Obtain the object
# Obtain the NexTrieve object
# Obtain the HTML, id, date and source
# Obtain the initial encoding after checking for UTF-32 and UTF-16

  my $self = shift;
  my $ntv = $self->NexTrieve;
  my ($html,$id,$date,$source) = $self->_fetch_content( @_ );
  my $encoding = $self->utf3216check( $html );

# Obtain an empty Document object
# Remember the source if a filename was specified
# Adapt source for display if source available

  my $document = $ntv->Document;
  $document->{ref($document).'::SOURCE'} = $source if $source;
  $source .= ': ' if $source;

# Get rid of any conceptual null bytes (if they're there, they're of no use)
# Obtain the length to be processed
# If there is nothing to do
#  Return now with error
# Make sure all of the tags are in lowercase (simplifies further matching)

  $html =~ s#[\0\x0b\x0c\x1a]##sg;
  my $length = length($html);
  unless ($length) {
    return $document->_add_error( "${source}No HTML to be processed" );
  }
  $html =~ s#(</?\w+)#\L$1\E#sgi;

# If we're supposed to do the binary file check
#  Calculate the number of ISO-8859-1 illegal characters
#  If we think they indicate a binary file
#   Put out an error and return

  if ($self->binarycheck) {
    my $count = $html =~ tr#\x00-\x08\x0b-\x0c\x0e-\x1a\x1c-\x1f##;
    if ($count > 100 or $count/$length > .01) {
      return $document->_add_error( "${source}Probably binary" );
    }
  }

# Initialize the content hash
# If there is a preprocessor, obtaining it on the fly
#  Run the preprocessor
# Get rid of anything that looks like a comment

  my %content = (id => $id, date => $date);
  if (my $preprocessor = $self->preprocessor) {
    &{$preprocessor}( \%content,$html );
  }
  $html =~ s#<!--.*?-->##sg;

# Obtain the name of the containers to be removed with their content
# Get rid of anything that should be removed

  my $containers = $self->removecontainers || $removecontainers;
  $html =~ s#<($containers)\b[^>]*>.*?</\1[^>]*>##sg;

# If we don't have an encoding yet
#  Obtain the meta tag for content-type, if any
#  Obtain the content encoding (if any)
# Set the encoding

  unless ($encoding) {
    $encoding =
     $html =~ m#(<meta[^>]+http-equiv="content-type"[^>]*>)#si ? $1 : '';
    $encoding = $encoding =~ m#content="text/html;\s*charset=([^"]+)"#si ?
     $1 : $self->encoding || $self->DefaultInputEncoding;
    $document->encoding( $encoding );
  }

# For all of the meta name/content tags to check
#  If there is a meta tag for this name
#   Store the content of that meta-tag for later processing

  foreach my $tag (qw(author description generator keywords)) {
    if (my $value = $html =~ m#(<meta[^>]+name="$tag"[^>]*>)#si ? $1 : '') {
      $content{$tag} = $1 if $value =~ m#content="([^"]+)"#si;
    }
  }
  
# Obtain the title (if any)
# Get rid of anything left in the head
# Get rid of HTML and BODY tags (rest should be "valid" html

  $content{'title'} = $1 if $html =~ s#<title[^>]*>(.*?)</title[^>]*>##s;
  $html =~ s#<head[^>]*>.*?</head[^>]*>##sgi;
  $html =~ s#</?(?:html|body)[^>]*>##sgi;

# Obtain the display containers
# For all of the content that we want to check
#  Reloop if nothing to do
#  Throw away any displayable containers inside the html completely
#  Replace all other containers by a space

  $containers = $self->displaycontainers || $displaycontainers;
  foreach (qw(description keywords title)) {
    next unless exists( $content{$_} ) and defined( $content{$_} );
    $content{$_} =~ s#<($containers)\b[^>]*>(.*?)</\1[^>]*>#$2#sg;
    $content{$_} =~ s#<[^<>]*># #sg;
  }

# If there is (still) html to process
#  Throw away any displayable containers inside the html completely
#  Replace all other containers by a space
#  Make sure we have valid XML for the html text

  if ($html) {
    $html =~ s#<($containers)\b[^>]*>(.*?)</\1[^>]*>#$2#sg;
    $html =~ s#</?[\w!][^<>]*># #sg;
    $self->normalize( $html );
  }

# Create and store the XML
# Return the document

  $self->_hashprocextra( $document,$id,\%content,$html,'normalize' );
  return $document;
} #Document

#------------------------------------------------------------------------

# Following methods change the object

#------------------------------------------------------------------------

# OUT: 1 the object itself

sub asp {

# Obtain the object
# Set the preprocessor to remove all ASP-style tags
# Return the object (handy for oneliners)

  my $self = shift;
  $self->preprocessor( sub {$_[1] =~ s#<%.*?%>##sg} );
  return $self;
} #asp

#------------------------------------------------------------------------

# OUT: 1 the object itself

sub htmlsimple {

# Obtain the object
# Set the htmlsimple attributes

  my $self = shift;
  $self->field2attribute(
   [qw(id filename string key-unique 1)],
   [qw(title title string notkey 1)],
  );

# Set the htmlsimple textttypes

  $self->field2texttype( qw(
   title
   description
   keywords
  ) );

# Return the object (handy for oneliners)

  return $self;
} #htmlsimple

#------------------------------------------------------------------------

# OUT: 1 the object itself

sub mhonarc {

# Obtain the object
# Set the mhonarc attributes

  my $self = shift;
  $self->field2attribute(
   [qw(from from string notkey 1)],
   [qw(subject subject string notkey 1)],
   [qw(date date number notkey 1)],
   [qw(id mailbox string key-unique 1)],
  );

# Set the mhonarc textttypes

  $self->field2texttype( qw(
   subject
  ) );

# Set the attribute processors

  $self->attribute_processor(
   [qw(date datestamp)],
  );

# Set the preprocessor with the following anonymous subroutine

  $self->preprocessor( sub {

#  Obtain the reference to the content hash
#  For all the basic stuff
#   Add to content hash if we found it

    my $content = shift;
    foreach my $key (qw(Subject From Date)) {
      ($content->{lc($key)} = $1) =~ s/&#45;/-/sg
       if $_[0] =~ m#<!--X-$key:\s*(.*?)\s*-->#s;
    }

#  Set the rest of the stuff that we need to process

    $_[0] = $1 if $_[0] =~ m#<pre>\s*(.*)</pre>#s;
  } #sub
  );

# Return the object (handy for oneliners)

  return $self;
} #mhonarc

#------------------------------------------------------------------------

# OUT: 1 the object itself

sub php {

# Obtain the object
# Set the preprocessor to remove all PHP and ASP-style tags
# Return the object (handy for oneliners)

  my $self = shift;
  $self->preprocessor( sub {$_[1] =~ s#<([?%]).*?\1>##sg} );
  return $self;
} #php

#------------------------------------------------------------------------

#  IN: 1 new setting of preprocessor
# OUT: 1 current/old setting of preprocessor flag

sub preprocessor { shift->_class_variable( 'preprocessor',@_ ) } #preprocessor

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::HTML - convert HTML to NexTrieve Document objects

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );

 $converter = $ntv->HTML( | {method => value} );

 $index = $ntv->Index( $resource )->htmlsimple;
 $docseq = $index->Docseq;
 foreach my $file (<*.html>) {
   $docseq->add( $converter->Document( $file ) );
 }
 $docseq->done;

=head1 DESCRIPTION

The HTML object of the Perl support for NexTrieve.  Do not create
directly, but through the HTML method of the NexTrieve object.

The "html2ntvml" script is basically a directly configurable and executable
wrapper for the NexTrieve::HTML module.

=head1 CONVERSION PROCESS

The conversion of an HTML-file consists of basically five phases:

 - creating the NexTrieve::HTML object
 - setting the appropriate parameters
 - obtain the HTML from the indicated source
 - setting up the content hash (an internal representation of the HTML)
 - serializing the content hash to XML

More specifically, the following steps are performed.

=over 2

=item create NexTrieve::HTML object

You must create the NexTrieve::HTML object by calling the "HTML" method of the
NexTrieve object.  You can set any parameters directly with the creation of
the object by specifying a hash with method names and values.  Or you can set
the parameters later by calling the methods on the object.

=item setting parameters

After the object is created, you will have to decide if a preprocessor should
process the HTML before anything else (see L<preprocessor>), which fields of
the content hash should appear as what attributes (see L<field2attribute>)
and/or texttypes (see L<field2texttype>).

You should also think about extra attributes (see L<extra_attribute>) and/or
texttypes (see L<extra_texttype>) that should be added to the XML that are not
part of the original HTML.  And you should consider if any conversions should
be done on the information that is destined to become an attribute (see
L<attribute_processor>) or a texttype (see L<texttype_processor>), before
they are actually serialized into XML.

By setting up all of this information, you may find it handy to use the
L<Resource> method for setting up the basic resource-file that could be used by
NexTrieve to index the XML generated by these settings.

=item read HTML from the indicated source

The next step is getting a copy of the HTML for which to create XML that
can be indexed.  This is done when the L<Document> object is created.  The
HTML can either be specified directly, as a filename or as a URL.  A content
hash with the "id" field (either the filename or the URL, or whatever was
specified directly) and the "date" field (last modified info from the file
or the URL, or whatever was specified directly) is initialized.

=item optional binary check

If you are unsure whether the input really _is_ HTML, you can specify a
L<binarycheck> to be executed.  After any preprocessing is done, the binary
check is performed if so specified.  If the input is considered to be binary,
then the entire input is ignored, an error message issued and no XML is
returned.

=item pre-process the HTML

If a preprocessor routine was specified, it will be executed now.  The
preprocessor routine takes a reference to the content hash and the HTML as its
input and return (possibly adapted) HTML.  The preprocessor routine has access
to the content hash and is able to add, change or remove fields from the
content hash as it seems fit.

No action is performed if no processor routine is specified.  Please note
however that by calling methods such as L<asp>, L<php> and L<mhonarc>, you
are in fact specifying a preprocessor routine.

=item remove comments and completely removable HTML-tags

At this point, any HTML-comments, in the form <!--  ...  --> are removed.
Then the HTML-tags that may contain information that you do _not_ want to be
indexed, are removed.  You can specify which HTML-tags conform to this with
the L<removecontainers> method.  By default, only the <script..>...</script>
are removed, causing any Javascript to be removed.

=item extract "known" information from the HTML

The next step involves searching the HTML for known pieces of information.
As of this writing these contain:

 - title, as found in <TITLE>...</TITLE>
 - encoding information as found in <META HTTP-EQUIV....>
 - other information found in <META name="" content=""> tags

At the end of this step, the content hash can be enriched with the following
fields (in alphabetical order):

 - author
 - description
 - encoding
 - generator
 - keywords
 - title

If no encoding information is found, the HTML is considered to be encoded in
"ISO-8859-1", an encoding that is a superset of "us-ascii" that in practice
seems to be the most appropriate to use for HTML.

=item removing the HTML-tags

Before the HTML can be converted to XML, all of the remaining HTML-tags need
to be removed from the HTML.  This is done by removing anything between
<HEAD>...</HEAD>.  Then any existing <HTML>, <BODY>, </BODY> and </HTML>
themselves are removed.  Whatever remains then is considered to be the basis
of the final text of the XML.

Then the HTML-tags that are considered to be "display" containers, such as
<B>, <I> and <U>, are removed B<without> replacing them by a space.  This is
done this way because it often happens that only a single letter of a word is
highlighted with these HTML-tags.  If these tags would be replaced by a space,
then the words would be broken up.

If you have any HTML-tags that you would like to be processed the same way,
you can specify these with the L<displaycontainers> method.

After this, all other tags are replaced by spaces.

=item serializing the XML

When all of this is done, all of the information in the content hash as well
as the remaining text (from the original HTML) are fed to a generic
serialization routine that is also used by the NexTrieve::RFC822 and
NexTrieve::DBI modules.

This serialization routine looks for any extra attributes and/or texttypes and
processor routines, executes them in the correct order and generates the XML
for the HTML that was provided on input.

If you want to access the XML, you can call the L<xml> method, which is
inherited from the NexTrieve module.

=back

=head1 OBJECT CREATION METHODS

These methods create objects from the NexTrieve::HTML object.

=head2 Docseq

 $docseq = $converter->Docseq( @file );
 $docseq->write_file( filename );

 $index = $ntv->Index( $resource );
 $converter->Docseq( $index->Docseq,@file );

The Docseq method allows you to create a NexTrieve document sequence object
(or NexTrieve::Docseq object) out of one or more HTML-files.  This can either
be used to be directly indexed by NexTrieve (through the NexTrieve::Index
object) or to create the XML of the document sequence in a file for indexing
at a later stage.

The first (optional) input parameter is an (already existing)
NexTrieve::Docseq object that should be used.  This can either be a special
purpose NexTrieve::Docseq object as created by the NexTrieve::Index module,
or a NexTrieve::Docseq object that was created earlier on which a second
run of HTML-files need to be added.

The rest of the input parameters indicate the HTML-sources that should be
indexed.  These can either be just filenames, or URL's in the form:
file://directory/file.html  or  http://server/filename.html.

For more information, see the NexTrieve::Docseq module.

=head2 Document

 $document = $converter->Document( file | html | [list] , | '' | 'file' | 'url' | sub {} );

The Document method performs the actual conversion from HTML to XML and
returns a NexTrieve::Document object that may become part of a NexTrieve
document sequence (see L<Docseq>).

The first input parameter specifies the source of the HTML.  It can consist of:

- HTML itself

If the second parameter is specified and is set to '', then the first input
parameter is considered to be the HTML to be processed.   If the second input
parameter is not specified at all, the first input parameter will be considered
to be the HTML if a newline character can be found.

- a filename

If the second input parameter is specified as "file", then the first input
parameter is considered to be a filename.  If no second input parameter is
specified, then the first parameter is considered to be a filename if B<no>
newline character can be found.

- a URL

If the second input parameter is specified as "url", then the first input
parameter is considered to be a URL from which to fetch the HTML.  If the second
input parameter is not specified, but the first input parameter starts with
what looks like a protocol specification (^\w+://), then the first input
parameter is considered to be a URL.  Two protocols are currently supported:
file:// and http://.

- a reference to a list

If the first input parameter is a reference to a list, then that list is
supposed to contain:

 - the HTML to be processed
 - the "id" to be used to identify this HTML
 - the epoch time when the HTML was last modified (when available)
 - an indication of the source of the HTML (for error messages, if any)

- anything else

If the second input parameter is specified as a reference to an (anonymous)
subroutine, then that routine is called.  That "fetch" routine should expect
to be passed:

 - whatever was specified with the first input parameter
 - whatever other input parameters were specified

The fetch routine is expected to return in scalar context just the HTML that
should be processed.  In list context, it is expected to return:

 - the HTML to be processed
 - the "id" to be assigned to this HTML (usually the first input parameter)
 - the epoch time when the HTML was last modified (when available)
 - an indication of the source of the HTML (for error messages, if any)

=head2 Resource

 $resource = $converter->Resource( | {method => value} );

The "Resource" method allows you to create a NexTrieve::Resource object from
the internal structure of the NexTrieve::HTML.pm object.  More specifically,
it takes the information as specified with the L<extra_attribute,
L<field2attribute>, L<extra_texttype> and L<field2texttype> methods and creates
the <indexcreation> section of the NexTrieve resource file as specified on
http://www.nextrieve.com/usermanual/2.0.0/ntvresourcefile.stm .

For more information, see the documentation of the NexTrieve::Resource module
itself.

=head1 OTHER METHODS

These methods change aspects of the NexTrieve::HTML object.

=head2 asp

 $converter->asp;

The "asp" method makes sure that <%...%> processor tags are removed from the
HTML before being processed.  It basically defined a L<preprocessor> routine
to do so.

The "asp" method returns the object itself, so that it can be used in
one-liners.

=head2 attribute_processor

 $converter->attribute_processor( 'attribute', key | sub {} );

The "attribute_processor" allows you to specify a subroutine that will process
the contents of a specific attribute before it becomes serialized in XML.

The first input parameter specifies the name of the attribute as it will be
serialized.  Please note that this may not be the same as the name of the
content hash field.

The second input parameter specifies the processor routine.  See
L<PROCESSOR ROUTINES> for more information.

=head2 binarycheck

 $converter->binarycheck( true | false );
 $binarycheck = $converter->binarycheck;

The "binarycheck" method sets a flag in the object to indicate whether a
check for binary content should be performed.  If the flag is set and binary
content is assumed to be found, conversion will be aborted and an error will
be set.

This method is mainly intended if you are unsure about the cleanliness of the
list of files that you want to process.  If you are not sure that all files
listed are really HTML, it is probably a good idea to set this flag.

=head2 DefaultInputEncoding

 $encoding = $converter->DefaultInputEncoding;
 $converter->DefaultInputEncoding( encoding );

See the NexTrieve.pm module for more information about the
"DefaultInputEncoding" method.

=head2 displaycontainers

 $converter->displaycontainers( qw(a b em font i strike strong tt u) );
 @displaycontainer= $converter->displaycontainers;

The "displaycontainers" method specifies which HTML-tags should be considered
HTML-tags that have to do with the display of HTML, rather than with the
structure of HTML.  During the conversion from HTML to XML, all HTML-tags
that are considered to be display containers, are completelyb removed from
the HTML.  This causes the HTML "<B>1</B>234" to be converted to the single
word "1234" rather than to two words "1 234".

Please note that all HTML-tags that are not known to be display containers,
or removable containers (see L<removecontainers>) are completely removed from
the HTML during the conversion process.

The default display containers are: a b em font i strike strong tt u .

=head2 extra_attribute

 $converter->extra_attribute( [\$var | sub {}, attribute spec] | 'reset' );

The "extra_attribute" method specifies one or more attributes that should be
added to the serialized XML, created from sources outside of the original HTML.

Each input parameter specifies a single attribute as a reference to a list of
parameters.  These parameters consist of:

 - a reference to a variable or subroutine
 - an attribute specification

If the first parameter in the list consists of a reference to a variable, then
the value of that variable will be used for that attribute at the moment the
XML is serialized.  This could e.g. be an external counter variable.

If the first parameter in the list consists of a reference to a subroutine,
then that subroutine is called as a processor routine when the XML is
serialized.  The first input parameter is the contents of the "id" field in
the content hash and can e.g. be used by the processor routine for a database
lookup.  See L<PROCESSOR ROUTINES> for more information.

The rest of the list consists of an attribute specification.  See
L<ATTRIBUTE SPECIFICATION> for more information.

As a special function, the string "reset" may also be specified as the first
input parameter to the method: it will then remove any extra attribute
specifications from the object that were specified previously in the lifetime
of the object.

=head2 extra_texttype

 $converter->extra_texttype( [\$var | sub {}, texttype spec] | 'reset' );

The "extra_texttype" method specifies one or more texttypes that should be
added to the serialized XML, created from sources outside of the original HTML.

Each input parameter specifies a single texttype as a reference to a list of
parameters.  These parameters consist of:

 - a reference to a variable or subroutine
 - a texttype specification

If the first parameter in the list consists of a reference to a variable, then
the value of that variable will be used for that texttype at the moment the
XML is serialized.  This could e.g. be an externally stored title.

If the first parameter in the list consists of a reference to a subroutine,
then that subroutine is called as a processor routine when the XML is
serialized.  The first input parameter is the contents of the "id" field in
the content hash and can e.g. be used by the processor routine for a database
lookup.  See L<PROCESSOR ROUTINES> for more information.

The rest of the list consists of a texttype specification.  See
L<TEXTTYPE SPECIFICATION> for more information.

As a special function, the string "reset" may also be specified as the first
input parameter to the method: it will then remove any extra texttype
specifications from the object that were specified previously in the lifetime
of the object.

=head2 field2attribute

 $converter->field2attribute( 'title','date',['id',attribute spec] );

The "field2attribute" specifies how a key in the content hash should be mapped
to an attribute in the serialized XML.

Each input parameter specifies a single mapping.  It either consists of the
key (which causes that key to be serialize as an attribute with the same name)
or as a reference to a list.

If a parameter is a reference to a list, then the first element of that list
is the key in the content hash.  The rest of the list is then considerd to be
an attribute specification (see L<ATTRIBUTE SPECIFICATION> for more
information).

So, for example, just the string 'title' would cause the content of the key
"title" in the content hash to be serialized as the attribute "title".

As another example, the list "[qw(id filename string key-unique 1)]" would
cause the content of the "id" to be serialized as the attribute "filename" and
cause a complete resource-specification if the L<Resource> method is called.

=head2 field2texttype

 $converter->field2texttype( 'title',[qw(description whatitis 200)],'keywords' );

The "field2texttype" specifies how a key in the content hash should be mapped
to a texttype in the serialized XML.

Each input parameter specifies a single mapping.  It either consists of the
key (which causes that key to be serialize as a texttype with the same name)
or as a reference to a list.

If a parameter is a reference to a list, then the first element of that list
is the key in the content hash.  The rest of the list is then considerd to be
a texttype specification (see L<TEXTTYPE SPECIFICATION> for more
information).

So, for example, just the string 'title' would cause the content of the key
"title" in the content hash to be serialized as the texttype "title".

As another example, the list "[qw(description whatitis 200)]" would
cause the content of the "description" key to be serialized as the texttype
"whatitis" and cause a complete resource-specification if the L<Resource>
method is called.

=head2 htmlsimple

 $converter->htmlsimple;

The "htmlsimple" method is a convenience method for quickly setting up
L<field2attribute> and L<field2texttype> mappings.  It is intended to handle
simple HTML-pages.  Currently, the following mappings are performed:

 - key "id" serialized as "filename" attribute
 - key "title" serialized as both attribute and texttype with same name
 - keys "description" and "keywords" serialized as texttypes with same name

The "htmlsimple" method returns the object itself, so that it can be used in
one-liners.

=head2 mhonarc

 $converter->mhonarc;

The "mhonarc"  method is a convenience method for quickly setting up
L<field2attribute>, L<field2texttype>, L<attribute_processor> and
L<preprocessor> settings.  It is intended to handle HTML-pages that are
created by MHonArc (see http://www.mhonarc.org for more information).

Currently, the following mappings are performed:

 - a preprocessor that fills content hash with "subject", "date" and "title"
 - a preprocessor that throws away anything that's not between <pre> and </pre>
 - key "id" serialized as "mailbox" attribute
 - key "date" serialized as "date" attribute, converted to "datestamp"
 - key "subject" serialized as both an attribute and texttype with same name
 - key "from" serialized as attribute with same name

The "mhonarc" method returns the object itself, so that it can be used in
one-liners.

=head2 php

 $converter->php;

The "php" method makes sure that <?...?> and <%...%> processor tags are removed
from the HTML before being processed.  It basically defined a L<preprocessor>
routine to do so.  Please note that the third way of removing PHP processor
tags, the <script language="php"...>...</script>, is by default already handled
by the L<removecontainers> specification.

The "php" method returns the object itself, so that it can be used in
one-liners.

=head2 preprocessor

 $converter->preprocessor( \&preprocess );
 $preprocessor = $converter->preprocessor;

The "preprocessor" method allows you to specify a subroutine that will be
executed before any of the other conversions take place on the input HTML.

When specified, the subroutine should be ready to expect the following input
parameters:

- reference to content hash

The content hash has been initialized with the "id" and "date" keys when the
preprocessor is called.  The preprocessor subroutine can make any changes to
the content hash that it seems fit.  An example of the use of a preprocessor
subroutine is the L<mhonarc> convenience method that extracts subject, from
and date information from the HTML which are stored in the content hash.

- HTML to be pre-processed

The second input parameter is the HTML that should be preprocessed.  The result
of this preprocessing should be returned by the subroutine or directly changed
in the parameter passed.

=head2 removecontainers

 $converter->removecontainers( qw(embed script) );
 @removecontainer= $converter->removecontainers;

The "removecontainers" method specifies which HTML-tags, and their content,
should be removed from the HTML when converting to XML.  The difference with
the L<displaycontainers> is that in this case, everything between the opening
and closing HTML-tag is B<also> removed.

The default HTML-tags are: embed script .

=head2 texttype_processor

 $converter->texttype_processor( 'attribute', key | sub {} );

The "texttype_processor" allows you to specify a subroutine that will process
the contents of a specific texttype before it becomes serialized in XML.

The first input parameter specifies the name of the texttype as it will be
serialized.  Please note that this may not be the same as the name of the
content hash field.

The second input parameter specifies the processor routine.  See
L<PROCESSOR ROUTINES> for more information.

=head1 ATTRIBUTE SPECIFICATION

An attribute specification can be very simple: just the name of the attribute,
e.g. 'date'.  If you would like to use the L<Resource> method to create the
<indexcreation> section of the NexTrieve resource-file, then it is wise to
add the type of attribute, key and multiplicity information as well, as
described in http://www.nextrieve.com/usermanual/2.0.0/ntvresourcefile.stm .

A complete attribute specification would be "'date','number','notkey','1'".
Which of course can be more easily expressed as "qw(date number notkey 1)".

Please note that future versions of NexTrieve may add more fields to the
complete attribute specification.  So watch this space for more info in the
future.

=head1 PROCESSOR ROUTINES

Processor routines can be either a reference to an (anonymous) subroutine or a
key to one of the available subroutines for doing standard conversions.

If a processor routine is a reference to an (anonymous) subroutine, then that
subroutine should expect the following input parameters:

 - the data to be processed
 - the name of the attribute it will be serialized to
 - the document object for which the XML will be serialized

The subroutine is expected to return the processed data.

If the second input parameter is a key, it must be one of the following:

- datestamp

Attempt to convert the input to a datestamp in the form YYYYMMDD.  The
Date::Parse module must be available for this to work.

- epoch

Attempt to convert the input to a Unix epoch time value (number of seconds
since midnight Jan. 1st 1970 GMT).  The Date::Parse module must be available
for this to work.

- timestamp

Attempt to convert the input to a timestamp in the form YYYYMMDDHHMMSS.  The
Date::Parse module must be available for this to work.

Other keyed processor routines may be added in the future, so please check
this space for additions.

=head1 TEXTTYPE SPECIFICATION

A texttype specification can be very simple: just the name of the texttype,
e.g. 'title'.  If you would like to use the L<Resource> method to create the
<indexcreation> section of the NexTrieve resource-file, then it is wise to
add any extra information as well, as described in
http://www.nextrieve.com/usermanual/2.0.0/ntvresourcefile.stm .

A complete texttype specification would be "'title','200'".  Which of course
can be more easily expressed as "qw(title 200)", which would make the "title"
twice as important in exact searches by default than the other texttypes.

Please note that future versions of NexTrieve may add more fields to the
complete texttype specification.  So watch this space for more info in the
future.

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
