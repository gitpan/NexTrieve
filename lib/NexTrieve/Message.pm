package NexTrieve::Message;

# Set modules to inherit from
# Set version information
# Make sure we do everything by the book from now on

@ISA = qw(NexTrieve);
$VERSION = '0.40';
use strict;

# Use other NexTrieve modules that we need always

use NexTrieve::Docseq ();
use NexTrieve::Document ();
use NexTrieve::MIME ();

# Initialize the reference to the hash with routines for handling the text

my $mimeprocessor = NexTrieve::MIME::processor();

# Satisfy -require-

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 Mail::Message object
# OUT: 1 instantiated NexTrieve::Document object

sub Document {

# Obtain the object
# Obtain the NexTrieve object
# Obtain the message object
# Obtain the head object
# Obtain the ID
# Obtain the date

  my $self = shift;
  my $ntv = $self->NexTrieve;
  my $message = shift;
  my $head = $message->head;
  my $id = $message->messageId;
  my $date = $message->timestamp;

# Obtain an empty Document object

  my $document = $ntv->Document;

# Obtain the class of the object
# Obtain local copy of attribute hash
# Obtain local copy of text hash

  my $class = ref($self);
  my $attrhash = $self->{$class.'::attrhash'} || {};
  my $texthash = $self->{$class.'::texthash'} || {};

# Initialize the content hash
# Obtain the character encoding (if any)
# Obtain the multipart flag
# Set the document character encoding if there are no attachments

  my %content = (id => [$id], date => [$date]);
  my $encoding = $head->encoding;
  my $multipart = $head->isMultipart;
  $document->encoding( $encoding ) if $encoding and !$multipart;

# Create a hash with all the headers to be checked
# For all information keys to be handled
#  Add line keyed to header if to be handled further

  my %header = map {($_,1)} (keys %{$attrhash},keys %{$texthash});
  while (my $key = each %header) {
    push( @{$content{$key}},
     map {$_->toString =~ m#:\s*(.*)#; $1} $head->get( $key ) );
  }

# Initialize the text
# If it is a multi-part message
#  Process its parts

  my $text = '';
  if ($multipart) {
    $text = _process_parts( $self,$message,$document );

# Else
#  Obtain the mime-type
#  If we have a processor for this mimetype
#   Process the text and add to the texts we had

  } else {
    my $type = lc($head->get( 'content-type' ));
    if (my $processor =
     $self->{$class.'::mimeproc'}->{$type} || $mimeprocessor->{$type}) {
      $text = &{$processor}( $self,$message->decoded,$encoding,$document );
    }
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

#  IN: 1 NexTrieve::Message object
#      2 Mail::Message object
#      3 document object
# OUT: 1 text to be added (encoded in object's encoding)

sub _process_parts {

# Obtain the parameters
# Initialize the no error flag

  my ($self,$message,$document) = @_;
  my $noerror = '';

# Initialize text
# While we haven't reached the final boundary or end of file
#  Obtain object for header
#  If it is a multi-part within a multi-part
#   Call ourselves, add the result

  my $text = '';
  foreach my $part ($message->parts) {
    my $head = $part->head;
    if ($head->isMultipart) {
      $text .= _process_parts( $self,$part,$document );

#  Else
#   Obtain the mime-type
#   If there is a processor for this mimetype
#    Process this text with the appropriate processor

    } else {
      my $type = $head->get( 'content-type' );
      if (my $processor =
       $self->{ref($self).'::mimeproc'}->{$type} ||
       $mimeprocessor->{$type}) {
        $text .= &{$processor}(
         $self,
         $part->decoded,
         $self->_normalize_encoding( $head->encoding ),
         $document
        );
      }
    }
  }

# Return what we found here

  return $text ? "$text\n" : '';
} #_process_parts

#------------------------------------------------------------------------

# OUT: 1 the encoding of the header object

sub Mail::Message::Head::Complete::encoding {

# Obtain the head object
# Obtain the line object, return if failed
# Obtain the comment string, return if failed
# Return unless there is a charset specification in it
# Return the character encoding

  my $self = shift;
  my $line = $self->get( 'content-type' ) || return;
  my $comment = $line->comment || return;
  $comment =~ m#charset="?([^";]+)"?#i || return;
  return $1;
} #Mail::Message::Head::Complete::encoding

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Message - convert Mail::Message object(s) to document(s)

=head1 SYNOPSIS

 use Mail::Box::Manager;
 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $converter = $ntv->Message( | {method => value} );

 $mgr = Mail::Box::Manager->new;
 $folder = $mgr->open( folder => anymailbox );

 $document = $converter->Document( $folder->[0] ); # first message only

 $docseq = $converter->Docseq( $folder->messages ); # all messages in a folder
 $docseq->write_file( filename ); # saved as document sequence in file

 $docseq = $ntv->Index( $resource )->Docseq; # index on the fly
 $converter->Docseq( $docseq,$folder->messages ); # all messages in a folder
 $docseq->done;

=head1 DESCRIPTION

The Message object of the Perl support for NexTrieve.  Do not create
directly, but through the Message method of the NexTrieve object;

=head1 CONVERSION PROCESS

The conversion of a message as stored in a Mail::Message object consists of
basically five phases:

 - creating the NexTrieve::Message object
 - setting the appropriate parameters
 - obtaining the Mail::Message object
 - setting up the content hash (an internal representation of the message)
 - serializing the content hash to XML

More specifically, the following steps are performed.

=over 2

=item create NexTrieve::Message object

You must create the NexTrieve::Message object by calling the "Message" method of
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

The next step is getting the Mail::Message object for which to create XML that
can be indexed.  This is done when the L<Document> object is created.

=item optional binary check

If you are unsure whether the input really _is_ text, you can specify a
L<binarycheck> to be executed.  For each part of the message that can be
considered text, a binary check is then performed if so specified.  If the
input is considered to be binary, then that input is ignored, an error message
issued and that part of the message is ignored.

=item extract information from the header of the message

Extracting the header of a message is simple with the Mail::Message object:
you simply execute the "head" method.

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
NexTrieve::RFC822 and NexTrieve::DBI modules.

This serialization routine looks for any extra attributes and/or texttypes and
processor routines, executes them in the correct order and generates the XML
for the message that was provided on input.

If you want to access the XML, you can call the L<xml> method, which is
inherited from the NexTrieve module.

=back

=head1 OBJECT CREATION METHODS

These methods create objects from the NexTrieve::Message object.

=head2 Docseq

 $mgr = Mail::Box::Manager->new;
 $folder = $mgr->open( folder => filename );
 $docseq = $converter->Docseq( $folder->messages );
 $docseq->write_file( filename );

 $index = $ntv->Index( $resource );
 $converter->Docseq( $index->Docseq,$folder->messages );

The Docseq method allows you to create a NexTrieve document sequence object
(or NexTrieve::Docseq object) out of one or more Mail::Message objects.  This
can either be used to be directly indexed by NexTrieve (through the
NexTrieve::Index object) or to create the XML of the document sequence in a
file for indexing at a later stage.

The first (optional) input parameter is an (already existing)
NexTrieve::Docseq object that should be used.  This can either be a special
purpose NexTrieve::Docseq object as created by the NexTrieve::Index module,
or a NexTrieve::Docseq object that was created earlier on which a second
run of messages need to be added.

The rest of the input parameters indicate a list of Mail::Message objects that
should be indexed.

For more information, see the NexTrieve::Docseq module.

If you would like to index your Unix mailboxes only, you should check out the
NexTrieve::Mbox module.

=head2 Document

 $document = $converter->Document( $message );

The Document method performs the actual conversion from an RFC822-formatted
message contained in a Mail::Message object to XML and returns a
NexTrieve::Document object that may become part of a NexTrieve document
sequence (see L<Docseq>).

The input parameter specifies the Mail::Message object to be converted.

=head2 Resource

 $resource = $converter->Resource( | {method => value} );

The "Resource" method allows you to create a NexTrieve::Resource object from
the internal structure of the NexTrieve::Message.pm object.  More specifically,
it takes the information as specified with the L<extra_attribute,
L<field2attribute>, L<extra_texttype> and L<field2texttype> methods and creates
the <indexcreation> section of the NexTrieve resource file as specified on
http://www.nextrieve.com/usermanual/2.0.0/ntvresourcefile.stm .

For more information, see the documentation of the NexTrieve::Resource module
itself.

=head1 OTHER METHODS

These methods change aspects of the NexTrieve::HTML object.

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
listed are really messages, it is probably a good idea to set this flag.

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
structure of HTML.  During the conversion from any part of the message
considered to be HTML to XML, all HTML-tags that are considered to be display
containers, are completely removed from the HTML.  This causes the HTML
"<B>1</B>234" to be converted to the single word "1234" rather than to two
words "1 234".

Please note that all HTML-tags that are not known to be display containers,
or removable containers (see L<removecontainers>) are completely removed from
the HTML during the conversion process.

The default display containers are: a b em font i strike strong tt u .

=head2 extra_attribute

 $converter->extra_attribute( [\$var | sub {}, attribute spec] | 'reset' );

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

 $converter->extra_texttype( [\$var | sub {}, texttype spec] | 'reset' );

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

 $converter->field2attribute( 'subject','date',['id',attribute spec] );

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

 $converter->field2texttype( 'from',[qw(subject title 200)],'to' );

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

 $converter->mailsimple;

The "mailsimple" method is a convenience method for quickly setting up
L<field2attribute> and L<field2texttype> mappings.  It is intended to handle
simple messages.  Currently, the following mappings are performed:

 - key "date" serialized as "date" attribute with a "datetime" processor
 - key "from" serialized as "from" attribute
 - key "subject" serialized as both attribute and texttype with same name

The "mailsimple" method returns the object itself, so that it can be used in
one-liners.

=head2 removecontainers

 $converter->removecontainers( qw(embed script) );
 @removecontainer= $converter->removecontainers;

The "removecontainers" method specifies which HTML-tags, and their content,
should be removed from the HTML when converting any HTML found in a message
to XML.  The difference with the L<displaycontainers> is that in this case,
everything between the opening and closing HTML-tag is B<also> removed.

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
