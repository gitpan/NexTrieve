package NexTrieve::RFC822;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::RFC822::ISA = qw(NexTrieve);
$NexTrieve::RFC822::VERSION = '0.31';

# Use other NexTrieve modules that we need always

use NexTrieve::Docseq ();
use NexTrieve::Document ();
use NexTrieve::MIME ();

# Create the list of displaycontainers for matching (no space around it)
# Create the list of containers of which the content will be removed

my $displaycontainers = NexTrieve->_default_displaycontainers;
my $removecontainers = NexTrieve->_default_removecontainers;

# Initialize hash of transfer encoding types and decoding routines

my %decode = (
 'base64'		=> 'MIME::Base64::decode_base64',
 'quoted-printable'	=> 'MIME::QuotedPrint::decode_qp',
);

# For all of the encoding types
#  Create the module name
#  See if the module is available
#  Make sure we don't get errors in older Perl versions
#  If it is
#   Replace the entry by a code reference to the decoding routine
#  Else (module is not available)
#   Warn the user
#   Remove this encoding type (not supported now)

foreach (keys %decode) {
  my ($module) = $decode{$_} =~ m#^(.*)::#;
  eval( "use $module ()" );
  no strict 'refs';
  if (defined ${$module.'::VERSION'}) {
    $decode{$_} = \&{$decode{$_}};
  } else {
    warn qq(Cannot decode "$_": install $module module\n);
    delete( $decode{$_} );
  }
}

# Initialize the reference to the mime processors

my $mimeprocessor = NexTrieve::MIME::processor();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 filename or RFC822
#      2 type of input
#      3 reference to hash with attributes to be made available
# OUT: 1 instantiated NexTrieve::Document object

sub Document {

# Obtain the object
# Obtain the NexTrieve object
# Obtain the message and the id

  my $self = shift;
  my $ntv = $self->NexTrieve;
  my ($message,$id,$date,$source) = $self->_fetch_content( shift,shift );

# Obtain an empty Document object
# Remember the source if a filename was specified

  my $document = $ntv->Document;
  $document->{ref($document).'::SOURCE'} = $source if $source || '';

# Obtain the class of the object
# Obtain local copy of attribute hash
# Obtain local copy of text hash

  my $class = ref($self);
  my $attrhash = $self->{$class.'::attrhash'} || {};
  my $texthash = $self->{$class.'::texthash'} || {};

# Get rid of any null bytes (they're of no use if they're there)
# Return now if there is nothing to do
# Create the handle to read message from

  $message =~ s#\0##sg;
  return $document->_add_error( "No message to be processed" )
   unless length($message);
  my $handle = bless \$message,'NexTrieve::handle';

# Make sure we have a local copy of $_ otherwise strange things happen
# Create a hash with all the headers to be checked
# Create a single string for matching the headers to be handled

  local $_;
  my %header = map {($_,1)} (keys %{$attrhash},keys %{$texthash});
  my $headermatch = join( '|',keys %header );

# Initialize the content hash
# If there are extra values for the content hash
#  Loop for all of the keys in the hash
#   Copy the key and value

  my %content = $id ? (id => [$id]) : ();
  if (my $extra = shift) {
    foreach (keys %{$extra}) {
      $content{$_} = [$extra->{$_}];
    }
  }

# Obtain normalized header lines
# Get all the characteristics from the main header
# Set the document character encoding if there are no attachments

  my $header = $self->_normalize_header( $handle );
  my ($type,$boundary,$transferencoding,$characterencoding) =
   $self->_header_characteristics( $header );
  $document->encoding( $characterencoding ) if $characterencoding and !$boundary;

# For all of the header lines so far
#  Add line keyed to header if to be handled further

  foreach my $line (@{$header}) {
    push( @{$content{lc($1)}},$line ) if $line =~ s#^($headermatch):\s*##si;
  }

# Initialize the text
# If it is a multi-part message
#  Process its parts

  my $text = '';
  if ($boundary) {
    $text = _process_parts( $self,$handle,$document,$boundary );

# Elseif we have a processor for this mimetype
#  Handle any transfer encoding
#  Process the text and add to the texts we had

  } elsif (my $processor =
   $self->{$class.'::mimeproc'}->{$type} || $mimeprocessor->{$type} || '') {
    $message = _decode_transfer_encoding( $transferencoding,$handle->rest );
    $text = &{$processor}( $self,$message,$characterencoding,$document );
  }

# Create the field name for the HTML
# If there is HTML available
#  Use that as text if not available yet
#  Remove the HTML

  my $htmlfield = $class.'::html';
  if (exists $self->{$htmlfield}) {
    $text ||= $self->{$htmlfield};
    delete( $self->{$htmlfield} );
  }

# Set the default input encoding if still no encoding information
# Create and store the XML
# Return the document

  $document->encoding( $self->DefaultInputEncoding ) unless $document->encoding;
  $self->_hashprocextra( $document,$id,\%content,$text,'ampersandize' );
  return $document;
} #Document

#------------------------------------------------------------------------

# Following methods change the object

#------------------------------------------------------------------------

# OUT: 1 the object itself

sub mailsimple {

# Obtain the object
# Set the mailsimple attributes

  my $self = shift;
  $self->field2attribute(
   [qw(date date number notkey 1)],
   [qw(from from string notkey 1)],
   [qw(subject subject string notkey 1)],
  );

# Set the mailsimple textttypes

  $self->field2texttype( qw(
   subject
  ) );

# Set the attribute processors

  $self->attribute_processor(
   [qw(date datestamp)],
  );

# Return the object (handy for oneliners)

  return $self;
} #mailsimple

#------------------------------------------------------------------------

#  IN: 1..N reference to list with name of mimetype and coderef or keyword

sub mime_processor {
 shift->_processor_definition( 'mime',$mimeprocessor,@_ ) } #mime_processor

#------------------------------------------------------------------------

# Internal subroutines go here

#------------------------------------------------------------------------

#  IN: 1 transfer encoding (7/8bit,base64,quoted-printable)
#      2 text to be decoded
# OUT: 1 decoded text

sub _decode_transfer_encoding {

# Obtain the transferencoding
# Obtain the text

  my $transferencoding = shift;
  my $text = shift;

# If there is no decoding to be done
#  Just add this text to the total text
# Elseif we have a decoding routine for this encoding
#  Decode this text and add it to the total text
# Return without anything (couldn't decode)

  if (!$transferencoding or $transferencoding =~ m#^([78]bit|binary)$#) {
    return $text;
  } elsif (exists ($decode{$transferencoding})) {
    return &{$decode{$transferencoding}}( $text );
  }
  return '';
} #decode_transfer_encoding

#------------------------------------------------------------------------

#  IN: 1 reference to list with header lines
# OUT: 1 mime-type
#      2 boundary (if any)
#      3 transfer encoding (7/8bit,base64,quoted-printable, etc)
#      4 character encoding (windows-2512, iso-8859-1, etc)

sub _header_characteristics {

# Obain the object
# Initialize the variables needed here

  my $self = shift;
  my $mimetype = 'text/plain';
  my $boundary = '';
  my $transferencoding = '';
  my $characterencoding = '';

# Obtain the reference to the list
# For all of the lines in the header
#  If it is a line with "Content-Type:"
#   Save the actual type
#   Save the boundary if there is boundary information
#   Save the charset if there is charset information
#  Elseif it is a line with "Content-Transfer-Encoding"
#   Save the encoding

  my $list = shift;
  foreach my $line (@{$list}) {
    if ($line =~ m#^content-type:\s*([\w\-\_]+/[\w\-\_]+)#i) {
      $mimetype = lc($1);
      $boundary = $1 if $line =~ m#boundary="([^"]+)"#i;
      $characterencoding = $self->_normalize_encoding( $1 )
       if $line =~ m#charset="?([^";]+)"?#i;
    } elsif ($line =~ m#^content-transfer-encoding:\s*([\w\-]+)#i) {
      $transferencoding = $1;
    }
  }

# Return what we found

  return ($mimetype,$boundary,$transferencoding,$characterencoding);
} #_header_characteristics

#------------------------------------------------------------------------

#  IN: 1 handle to read header lines from
# OUT: 1 reference to list with header lines

sub _normalize_header {

# Obtain the object and the handle

  my ($self,$handle) = @_;

# Initialize the header list
# Initialize the line
# While there are lines to be read (obtaining it in $_)
#  Outloop if we reached end of headers

  my @header;
  my $line = '';
  while ($_ = $handle->nextnonewline || '') {
    last unless $_;

#  If this is a continuation line, losing any initial whitespace on the fly
#   Add it to what we already have, losing the delimiter on the fly

    if (s#^\s+##) {
      $line .= " $_";

#  Else (new line)
#   Add line to list
#   Start a new line

    } else {
      push( @header,$line );
      $line = $_;
    }
  }

# Add last line if there is one
# Return reference to list of headers

  push( @header,$line ) if $line;
  return \@header;
} #_normalize_header

#------------------------------------------------------------------------

#  IN: 1 RFC822 object
#      2 handle of message to be working on
#      3 document object
#      4 boundary found
# OUT: 1 text to be added (transfer decoded and encoded in object's encoding)

sub _process_parts {

# Obtain the parameters
# Initialize the no error flag

  my ($self,$handle,$document,$boundary) = @_;
  my $noerror = '';

# Prefix the start of boundary characters
# Set the length of the complete boundary
# Create the final boundary
# Set the length of the final boundary

  $boundary = "--$boundary";
  my $boundarylength = length($boundary);
  my $finalboundary = "$boundary--";
  my $finalboundarylength = length($finalboundary);

# While there is something to read
#  Outloop when the first boundary is reached
#  Error exit now if nothing left to read

  while ($_ = $handle->next) {
    last if substr($_,0,$boundarylength) eq $boundary;
    goto ERROR unless $handle->left;
  }

# Initialize text
# While we haven't reached the final boundary or end of file
#  Obtain normalized header lines
#  Get all the characteristics from the main header

  my $text = '';
  while (substr($_,0,$finalboundarylength) ne $finalboundary and $handle->left){
    my $header = $self->_normalize_header( $handle );
    my ($type,$thisboundary,$transferencoding,$characterencoding) =
     $self->_header_characteristics( $header );

#  If it is a multi-part within a multi-part
#   Call ourselves, add the result
#   Exit this level now if there is nothing else to do

    if ($thisboundary) {
      $text .= _process_parts( $self,$handle,$document,$thisboundary );
      last unless $handle->left;

#  Elseif there is a processor for this mimetype
#   Initialize text for this part
#   While there is something to be read
#    Outloop if next or last boundary reached
#    Outloop if attachment decoding error
#    Add this line to the text for this part

    } elsif (my $processor =
     $self->{ref($self).'::mimeproc'}->{$type} ||
     $mimeprocessor->{$type} || '') {
      my $thistext = '';
      while ($_ = $handle->next) {
        last if substr($_,0,$boundarylength) eq $boundary;
        goto ERROR unless $handle->left;
        $thistext .= $_;
      }

#   Remove the transfer encoding from the text
#   Process this text with the appropriate processor

      $thistext = _decode_transfer_encoding( $transferencoding,$thistext )
       if $thistext;
      $text .= &{$processor}( $self,$thistext,$characterencoding,$document )
       if $thistext;

#  Else (not something you can do with)
#   While there is something to be read
#    Outloop if next or last boundary reached (skip the line)
#    Error exit if attachment decoding error

    } else {
      while ($_ = $handle->next) {
        last if substr($_,0,$boundarylength) eq $boundary;
        goto ERROR unless $handle->left;
      }
    }
  }

#  Initialize the no error flag
#  Error label (go here if error on attachment decoding)
#  Warn user there is an attachment decoding error if there is one

  $noerror = 1;
ERROR:
  $document->_add_error( "Attachment error in message" ) unless $noerror;

# Return what we found here

  return $text ? "$text\n" : '';
} #_process_parts

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::RFC822 - convert RFC822 to NexTrieve Document objects

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );

 $rfc822 = $ntv->RFC822( | {method => value} );

 $document = $rfc822->Document( filename );

 $docseq = $rfc822->Docseq( $ntv->Index( $resource )->Docseq,<*.message> );
 $docseq->done;

=head1 DESCRIPTION

The RFC822 object of the Perl support for NexTrieve.  Do not create
directly, but through the RFC822 method of the NexTrieve object;

=head1 CONVERSION PROCESS

The conversion of a message as described in RFC822 (and following RFC's)
consists of basically five phases:

 - creating the NexTrieve::RFC822 object
 - setting the appropriate parameters
 - obtain the message from the indicated source
 - setting up the content hash (an internal representation of the message)
 - serializing the content hash to XML

More specifically, the following steps are performed.

=over 2

=item create NexTrieve::RFC822 object

You must create the NexTrieve::RFC822 object by calling the "RFC822" method of
the NexTrieve object.  You can set any parameters directly with the creation of
the object by specifying a hash with method names and values.  Or you can set
the parameters later by calling the methods on the object.

=item setting parameters

After the object is created, you will have to decide which fields of
the content hash should appear as what attributes (see L<field2attribute>)
and/or texttypes (see L<field2texttype>).

You should also think about extra attributes (see L<extra_attribute>) and/or
texttypes (see L<extra_texttype>) that should be added to the XML that are not
part of the original message.  And you should consider if any conversions
should be done on the information that is destined to become an attribute (see
L<attribute_processor>) or a texttype (see L<texttype_processor>), before
they are actually serialized into XML.

By setting up all of this information, you may find it handy to use the
L<Resource> method for setting up the basic resource-file that could be used by
NexTrieve to index the XML generated by these settings.

=item read message from the indicated source

The next step is getting a copy of the message for which to create XML that
can be indexed.  This is done when the L<Document> object is created.  The
message can either be specified directly, as a filename or as a URL.  A content
hash with the "id" field (either the filename or the URL, or whatever was
specified directly) and the "date" field (last modified info from the file
or the URL, or whatever was specified directly) is initialized.

=item optional binary check

If you are unsure whether the input really _is_ text, you can specify a
L<binarycheck> to be executed.  For each part of the message that can be
considered text, a binary check is then performed if so specified.  If the
input is considered to be binary, then that input is ignored, an error message
issued and that part of the message is ignored.

=item extract information from the header of the message

A message in RFC822 format basically consists of a header and a body.  The
header contains meta-information about the message, such as the originator,
subject, to whom it was sent when, etc.

This step involves reading each seperate line from the header (which consists
of a key and a content as well, in the form "Key: information") and adding that
to the content hash.  To allow for multiple instances of the same key (e.g.
the Received: key can occur multiple times in a header), each key in fact
becomes a reference to a list of values found with that key in the header.

The key names are normalized to be lowercase, so that e.g. "From" becomes the
"from" key in the content hash, and "Reply-To" becomes "reply-to".

If no encoding information is found, the HTML is considered to be encoded in
"ISO-8859-1", an encoding that is a superset of "us-ascii" that in practice
seems to be the most appropriate to use for HTML.

=item processing the (parts of the) body

Many messages nowadays consist of multiple parts.  The conversion process
involves a recursive process in which each part is converted to plain text
where possible.  If there is both an HTML as well as a text-version of a part,
then the HTML-version of that text will only be used if there is no
corresponding plain text version.

=item serializing the XML

When all of this is done, all of the information in the content hash as well
as the remaining text (from the original message) are fed to a generic
serialization routine that is also used by the NexTrieve::HTML,
NexTrieve::Message and NexTrieve::DBI modules.

This serialization routine looks for any extra attributes and/or texttypes and
processor routines, executes them in the correct order and generates the XML
for the message that was provided on input.

If you want to access the XML, you can call the L<xml> method, which is
inherited from the NexTrieve module.

=back

=head1 OBJECT CREATION METHODS

These methods create objects from the NexTrieve::RFC822 object.

=head2 Docseq

 $docseq = $rfc822->Docseq( @file );
 $docseq->write_file( filename );

 $index = $ntv->Index( $resource );
 $rfc822->Docseq( $index->Docseq,@file );

The Docseq method allows you to create a NexTrieve document sequence object
(or NexTrieve::Docseq object) out of one or more messages.  This can either
be used to be directly indexed by NexTrieve (through the NexTrieve::Index
object) or to create the XML of the document sequence in a file for indexing
at a later stage.

The first (optional) input parameter is an (already existing)
NexTrieve::Docseq object that should be used.  This can either be a special
purpose NexTrieve::Docseq object as created by the NexTrieve::Index module,
or a NexTrieve::Docseq object that was created earlier on which a second
run of messages need to be added.

The rest of the input parameters indicate the source of the messages that
should be indexed.  These can either be just filenames, or URL's in the form:
file://directory/file.txt  or  http://server/filename.txt.

For more information, see the NexTrieve::Docseq module.

If you would like to index your Unix mailboxes, you should check out the
NexTrieve::Mbox module.

=head2 Document

 $document = $rfc822->Document( file | html | [list] , | '' | 'file' | 'url' | sub {}, {extra} );

The Document method performs the actual conversion from an RFC822-formatted
message to XML and returns a NexTrieve::Document object that may become part
of a NexTrieve document sequence (see L<Docseq>).

The first input parameter specifies the source of the message.  It can consist
of:

- message itself

If the second parameter is specified and is set to '', then the first input
parameter is considered to be the message to be processed.   If the second input
parameter is not specified at all, the first input parameter will be considered
to be the message if a newline character can be found.

- a filename

If the second input parameter is specified as "file", then the first input
parameter is considered to be a filename.  If no second input parameter is
specified, then the first parameter is considered to be a filename if B<no>
newline character can be found.

- a URL

If the second input parameter is specified as "url", then the first input
parameter is considered to be a URL from which to fetch the message.  If the
second input parameter is not specified, but the first input parameter starts
with what looks like a protocol specification (^\w+://), then the first input
parameter is considered to be a URL.  Two protocols are currently supported:
file:// and http://.

- a reference to a list

If the first input parameter is a reference to a list, then that list is
supposed to contain:

 - the message to be processed
 - the "id" to be used to identify this message
 - the epoch time when the message was last modified (when available)
 - an indication of the source of the message (for error messages, if any)

- anything else

If the second input parameter is specified as a reference to an (anonymous)
subroutine, then that routine is called.  That "fetch" routine should expect
to be passed:

 - whatever was specified with the first input parameter
 - whatever other input parameters were specified

The fetch routine is expected to return in scalar context just the message that
should be processed.  In list context, it is expected to return:

 - the message to be processed
 - the "id" to be assigned to this message (usually the first input parameter)
 - the epoch time when the message was last modified (when available)
 - an indication of the source of the message (for error messages, if any)

The third input parameter is optional: it specifies a reference to a hash
with extra key-value pairs to be added to the content hash.  Values specified
in this way, will always be the first value for that key.

=head2 Resource

 $resource = $rfc822->Resource( | {method => value} );

The "Resource" method allows you to create a NexTrieve::Resource object from
the internal structure of the NexTrieve::RFC822.pm object.  More specifically,
it takes the information as specified with the L<extra_attribute,
L<field2attribute>, L<extra_texttype> and L<field2texttype> methods and creates
the <indexcreation> section of the NexTrieve resource file as specified on
http://www.nextrieve.com/usermanual/2.0.0/ntvresourcefile.stm .

For more information, see the documentation of the NexTrieve::Resource module
itself.

=head1 OTHER METHODS

These methods change aspects of the NexTrieve::RFC822 object.

=head2 attribute_processor

 $rfc822->attribute_processor( 'attribute', key | sub {} );

The "attribute_processor" allows you to specify a subroutine that will process
the contents of a specific attribute before it becomes serialized in XML.

The first input parameter specifies the name of the attribute as it will be
serialized.  Please note that this may not be the same as the name of the
content hash field.

The second input parameter specifies the processor routine.  See
L<PROCESSOR ROUTINES> for more information.

=head2 binarycheck

 $html->binarycheck( true | false );
 $binarycheck = $html->binarycheck;

The "binarycheck" method sets a flag in the object to indicate whether a
check for binary content should be performed.  If the flag is set and binary
content is assumed to be found, conversion will be aborted and an error will
be set.

This method is mainly intended if you are unsure about the cleanliness of the
list of files that you want to process.  If you are not sure that all files
listed are really messages, it is probably a good idea to set this flag.

=head2 DefaultInputEncoding

 $encoding = $rfc822->DefaultInputEncoding;
 $rfc822->DefaultInputEncoding( encoding );

See the NexTrieve.pm module for more information about the
"DefaultInputEncoding" method.

=head2 displaycontainers

 $rfc822->displaycontainers( qw(a b em font i strike strong tt u) );
 @displaycontainer= $rfc822->displaycontainers;

The "displaycontainers" method specifies which HTML-tags should be considered
HTML-tags that have to do with the display of HTML, rather than with the
structure of HTML.  During the conversion from any part of the message
considered to be HTML to XML, all HTML-tags that are considered to be display
containers, are completelyb removed from the HTML.  This causes the HTML
"<B>T</B>ext" to be converted to the single word "Text" rather than to two
words "T ext".

Please note that all HTML-tags that are not known to be display containers,
or removable containers (see L<removecontainers>) are completely removed from
the HTML during the conversion process.

The default display containers are: a b em font i strike strong tt u .

=head2 extra_attribute

 $rfc822->extra_attribute( [\$var | sub {}, attribute spec] | 'reset' );

The "extra_attribute" method specifies one or more attributes that should be
added to the serialized XML, created from sources outside of the original
message.

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

 $rfc822->extra_texttype( [\$var | sub {}, texttype spec] | 'reset' );

The "extra_texttype" method specifies one or more texttypes that should be
added to the serialized XML, created from sources outside of the original
message.

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

 $html->field2attribute( 'subject','date',['id',attribute spec] );

The "field2attribute" specifies how a key in the content hash should be mapped
to an attribute in the serialized XML.

Each input parameter specifies a single mapping.  It either consists of the
key (which causes that key to be serialize as an attribute with the same name)
or as a reference to a list.

If a parameter is a reference to a list, then the first element of that list
is the key in the content hash.  The rest of the list is then considerd to be
an attribute specification (see L<ATTRIBUTE SPECIFICATION> for more
information).

So, for example, just the string 'subject' would cause the content of the key
"subject" in the content hash to be serialized as the attribute "subject".

As another example, the list "[qw(id filename string key-unique 1)]" would
cause the content of the "id" to be serialized as the attribute "filename" and
cause a complete resource-specification if the L<Resource> method is called.

=head2 field2texttype

 $html->field2texttype( 'from',[qw(subject title 200)],'to' );

The "field2texttype" specifies how a key in the content hash should be mapped
to a texttype in the serialized XML.

Each input parameter specifies a single mapping.  It either consists of the
key (which causes that key to be serialize as a texttype with the same name)
or as a reference to a list.

If a parameter is a reference to a list, then the first element of that list
is the key in the content hash.  The rest of the list is then considerd to be
a texttype specification (see L<TEXTTYPE SPECIFICATION> for more
information).

So, for example, just the string 'from' would cause the content of the key
"from" in the content hash to be serialized as the texttype "from".

As another example, the list "[qw(subject title 200)]" would
cause the content of the "subject" key to be serialized as the texttype
"title" and cause a complete resource-specification if the L<Resource>
method is called.

=head2 mailsimple

 $html->mailsimple;

The "mailsimple" method is a convenience method for quickly setting up
L<field2attribute> and L<field2texttype> mappings.  It is intended to handle
simple messages.  Currently, the following mappings are performed:

 - key "date" serialized as "date" attribute with a "datetime" processor
 - key "from" serialized as "from" attribute
 - key "subject" serialized as both attribute and texttype with same name

The "mailsimple" method returns the object itself, so that it can be used in
one-liners.

=head2 removecontainers

 $rfc822->removecontainers( qw(embed script) );
 @removecontainer= $rfc822->removecontainers;

The "removecontainers" method specifies which HTML-tags, and their content,
should be removed from the HTML when converting any HTML found in a message
to XML.  The difference with the L<displaycontainers> is that in this case,
everything between the opening and closing HTML-tag is B<also> removed.

The default HTML-tags are: embed script .

=head2 texttype_processor

 $rfc822->texttype_processor( 'attribute', key | sub {} );

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

=head1 COPYRIGHT

Copyright (c) 1995-2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.nextrieve.com, the NexTrieve.pm and the other NexTrieve::xxx modules.

=cut
