package NexTrieve::PDF;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::PDF::ISA = qw(NexTrieve);
$NexTrieve::PDF::VERSION = '0.35';

# Use other NexTrieve modules that we need always

use NexTrieve::Docseq ();
use NexTrieve::Document ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 class
#      2..N program names to check (default: pdfinfo and pdftotext)
# OUT: 1 flag: whether program(s) (all) executable

sub executable {

# Obtain the class
# Set the filenames to check

  my $class = shift;
#  my $class = (@_ and $_[0] eq 'NexTrieve::PDF') ? shift : ''; # strange error
  my @program = @_ ? @_ : qw(pdfinfo pdftotext);

# For all the program names specified
#  Return false if strange characters in program name
#  Attempt to execute obtaining version info
#  Reloop if right exit code
#  Return indicating failure
# Return indicating success

  foreach my $program (@program) {
    return 0 if $program =~ m#\W#;
    my $exit = system( "$program -v 2>/dev/null" );
    next if $exit =~ m#^(?:0|256)$#;
    return 0;
  }
  return 1;
} #executable

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

sub _new {

# Obtain the object
# Return now if the necessary files are executable
# Return with error if not

  my $self = shift->SUPER::_new( @_ );
  return $self if __PACKAGE__->executable();
  return $self->_add_error(
   "Cannot find 'pdfinfo' and/or 'pdftotext' programs" );
} #_new

#------------------------------------------------------------------------

#  IN: 1 filename or PDF
#      2 type of input specification ('', 'filename' or 'url')
# OUT: 1 instantiated NexTrieve::Document object

sub Document {

# Obtain the object
# Obtain the NexTrieve object
# Obtain the PDF, id, date and source

  my $self = shift;
  my $ntv = $self->NexTrieve;
  my ($filename,$id,$date,$source) = $self->_fetch_file( @_ );

# Obtain an empty Document object
# Remember the source if a filename was specified
# Adapt source for display if source available

  my $document = $ntv->Document;
  $document->{ref($document).'::SOURCE'} = $source if $source || '';
  $source .= ': ' if $source;

# Attempt to get the information about this PDF-file
# Return now if failed

  my $handle = $self->openfile( "pdfinfo $filename |" );
  return $document unless $handle;

# Initialize the content hash
# While there are lines to be read
#  Reloop if it is a strange line
#  Obtain key (lowercase) and value
#  Make sure there is no whitespace in the key
#  Store the value in the content hash
# CLose the pipe

  my %content = (id => $id, date => $date);
  while (<$handle>) {
    next unless m#^(.*?):\s+(.*)$#;
    my ($key,$value) = (lc($1),$2);
    $key =~ s#\s##g;
    $content{$key} = $value;
  }
  close( $handle );

# Obtain the text of the PDF-file
# Return now if failed
  
  my $text = $self->slurp( $self->openfile( "pdftotext -raw $filename - |" ) );
  return $document unless length($text);

# Set the encoding
# If there is a preprocessor, obtaining it on the fly
#  Run the preprocessor
# Make sure we have valid XML for the text

  $document->encoding( 'iso-8859-1' );
  if (my $preprocessor = $self->preprocessor || '') {
    &{$preprocessor}( \%content,$text );
  }
  $self->ampersandize( $text );

# Create and store the XML
# Return the document

  $self->_hashprocextra( $document,$id,\%content,$text,'ampersandize' );
  return $document;
} #Document

#------------------------------------------------------------------------

# Following methods change the object

#------------------------------------------------------------------------

# OUT: 1 the object itself

sub pdfsimple {

# Obtain the object
# Set the pdfsimple attributes

  my $self = shift;
  $self->field2attribute(
   [qw(id filename string key-unique 1)],
   [qw(title title string notkey 1)],
  );

# Set the pdfsimple textttypes

  $self->field2texttype( qw(
   title
  ) );

# Return the object (handy for oneliners)

  return $self;
} #pdfsimple

#------------------------------------------------------------------------

#  IN: 1 new setting of preprocessor
# OUT: 1 current/old setting of preprocessor flag

sub preprocessor { shift->_class_variable( 'preprocessor',@_ ) } #preprocessor

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::PDF - convert PDF-file(s) to NexTrieve Document objects

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );

 $converter = $ntv->PDF( | {method => value} );

 $index = $ntv->Index( $resource )->pdfsimple;
 $docseq = $index->Docseq;
 foreach my $file (<*.pdf>) {
   $docseq->add( $converter->Document( $file ) );
 }
 $docseq->done;

=head1 DESCRIPTION

The PDF object of the Perl support for NexTrieve.  Do not create
directly, but through the PDF method of the NexTrieve object.

The "pdf2ntvml" script is basically a directly configurable and executable
wrapper for the NexTrieve::PDF module.

=head1 PREREQUISITES

Currently the "pdfinfo" and "pdftotext" programs of the xpdf package, located
at http://www.foolabs.com/xpdf/ , must be installed and operational.

=head1 CONVERSION PROCESS

The conversion of an PDF-file consists of basically five phases:

 - creating the NexTrieve::PDF object
 - setting the appropriate parameters
 - obtain the PDF from the indicated source
 - setting up the content hash (an internal representation of the PDF)
 - serializing the content hash to XML

More specifically, the following steps are performed.

=over 2

=item create NexTrieve::PDF object

You must create the NexTrieve::PDF object by calling the "PDF" method of the
NexTrieve object.  You can set any parameters directly with the creation of
the object by specifying a hash with method names and values.  Or you can set
the parameters later by calling the methods on the object.

=item setting parameters

After the object is created, you will have to decide if a preprocessor should
process the PDF before anything else (see L<preprocessor>), which fields of
the content hash should appear as what attributes (see L<field2attribute>)
and/or texttypes (see L<field2texttype>).

You should also think about extra attributes (see L<extra_attribute>) and/or
texttypes (see L<extra_texttype>) that should be added to the XML that are not
part of the original PDF.  And you should consider if any conversions should
be done on the information that is destined to become an attribute (see
L<attribute_processor>) or a texttype (see L<texttype_processor>), before
they are actually serialized into XML.

By setting up all of this information, you may find it handy to use the
L<Resource> method for setting up the basic resource-file that could be used by
NexTrieve to index the XML generated by these settings.

=item read PDF from the indicated source

The next step is getting a copy of the text of the PDF for which to create XML
that can be indexed.  This is done when the L<Document> object is created.  The
PDF can either be specified directly, as a filename or as a URL.  A content
hash with the "id" field (either the filename or the URL, or whatever was
specified directly) and the "date" field (last modified info from the file
or the URL, or whatever was specified directly) is initialized.

=item extract "known" information from the PDF

The next step involves searching the PDF for known pieces of information as
delivered by the "pdfinfo" program.  As of this writing these may contain:

 - author
 - creationdate
 - creator
 - encrypted
 - filesize
 - generator
 - moddate
 - optimized
 - pages
 - pagesize
 - pdfversion
 - producer
 - tagged
 - title

If no encoding information is found, the PDF is considered to be encoded in
"ISO-8859-1", an encoding that is a superset of "us-ascii" that in practice
seems to be the most appropriate to use for PDF.

=item pre-process the PDF

If a preprocessor routine was specified, it will be executed now.  The
preprocessor routine takes a reference to the content hash and the PDF as its
input and return (possibly adapted) PDF.  The preprocessor routine has access
to the content hash and is able to add, change or remove fields from the
content hash as it seems fit.

=item serializing the XML

When all of this is done, all of the information in the content hash as well
as the remaining text (from the original PDF) are fed to a generic
serialization routine that is also used by the NexTrieve::HTML,
NexTrieve::RFC822 and NexTrieve::DBI modules.

This serialization routine looks for any extra attributes and/or texttypes and
processor routines, executes them in the correct order and generates the XML
for the PDF that was provided on input.

If you want to access the XML, you can call the L<xml> method, which is
inherited from the NexTrieve module.

=back

=head1 CLASS METHODS

These methods are available as class methods.

=head2 executable

 NexTrieve::PDF->executable || die "cannot do PDF conversions";

 $executable = NexTrieve::PDF->executable;

Returns whether the external programs needed for PDF conversions, namely the
"pdfinfo" and "pdftotext" programs are available and executable.

=head1 OBJECT CREATION METHODS

These methods create objects from the NexTrieve::PDF object.

=head2 Docseq

 $docseq = $converter->Docseq( @file );
 $docseq->write_file( filename );

 $index = $ntv->Index( $resource );
 $converter->Docseq( $index->Docseq,@file );

The Docseq method allows you to create a NexTrieve document sequence object
(or NexTrieve::Docseq object) out of one or more PDF-files.  This can either
be used to be directly indexed by NexTrieve (through the NexTrieve::Index
object) or to create the XML of the document sequence in a file for indexing
at a later stage.

The first (optional) input parameter is an (already existing)
NexTrieve::Docseq object that should be used.  This can either be a special
purpose NexTrieve::Docseq object as created by the NexTrieve::Index module,
or a NexTrieve::Docseq object that was created earlier on which a second
run of PDF-files need to be added.

The rest of the input parameters indicate the PDF-sources that should be
indexed.  These can either be just filenames, or URL's in the form:
file://directory/file.pdf  or  http://server/filename.pdf.

For more information, see the NexTrieve::Docseq module.

=head2 Document

 $document = $converter->Document( file | pdf | [list] , | '' | 'file' | 'url' | sub {} );

The Document method performs the actual conversion from PDF to XML and
returns a NexTrieve::Document object that may become part of a NexTrieve
document sequence (see L<Docseq>).

The first input parameter specifies the source of the PDF.  It can consist of:

- PDF itself

If the second parameter is specified and is set to '', then the first input
parameter is considered to be the PDF to be processed.   If the second input
parameter is not specified at all, the first input parameter will be considered
to be the PDF if a newline character can be found.

- a filename

If the second input parameter is specified as "file", then the first input
parameter is considered to be a filename.  If no second input parameter is
specified, then the first parameter is considered to be a filename if B<no>
newline character can be found.

- a URL

If the second input parameter is specified as "url", then the first input
parameter is considered to be a URL from which to fetch the PDF.  If the second
input parameter is not specified, but the first input parameter starts with
what looks like a protocol specification (^\w+://), then the first input
parameter is considered to be a URL.  Two protocols are currently supported:
file:// and http://.

- a reference to a list

If the first input parameter is a reference to a list, then that list is
supposed to contain:

 - the PDF to be processed
 - the "id" to be used to identify this PDF
 - the epoch time when the PDF was last modified (when available)
 - an indication of the source of the PDF (for error messages, if any)

- anything else

If the second input parameter is specified as a reference to an (anonymous)
subroutine, then that routine is called.  That "fetch" routine should expect
to be passed:

 - whatever was specified with the first input parameter
 - whatever other input parameters were specified

The fetch routine is expected to return in scalar context just the PDF that
should be processed.  In list context, it is expected to return:

 - the PDF to be processed
 - the "id" to be assigned to this PDF (usually the first input parameter)
 - the epoch time when the PDF was last modified (when available)
 - an indication of the source of the PDF (for error messages, if any)

=head2 Resource

 $resource = $converter->Resource( | {method => value} );

The "Resource" method allows you to create a NexTrieve::Resource object from
the internal structure of the NexTrieve::PDF.pm object.  More specifically,
it takes the information as specified with the L<extra_attribute,
L<field2attribute>, L<extra_texttype> and L<field2texttype> methods and creates
the <indexcreation> section of the NexTrieve resource file as specified on
http://www.nextrieve.com/usermanual/2.0.0/ntvresourcefile.stm .

For more information, see the documentation of the NexTrieve::Resource module
itself.

=head1 OTHER METHODS

These methods change aspects of the NexTrieve::PDF object.

=head2 attribute_processor

 $converter->attribute_processor( 'attribute', key | sub {} );

The "attribute_processor" allows you to specify a subroutine that will process
the contents of a specific attribute before it becomes serialized in XML.

The first input parameter specifies the name of the attribute as it will be
serialized.  Please note that this may not be the same as the name of the
content hash field.

The second input parameter specifies the processor routine.  See
L<PROCESSOR ROUTINES> for more information.

=head2 DefaultInputEncoding

 $encoding = $converter->DefaultInputEncoding;
 $converter->DefaultInputEncoding( encoding );

See the NexTrieve.pm module for more information about the
"DefaultInputEncoding" method.

=head2 extra_attribute

 $converter->extra_attribute( [\$var | sub {}, attribute spec] | 'reset' );

The "extra_attribute" method specifies one or more attributes that should be
added to the serialized XML, created from sources outside of the original PDF.

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
added to the serialized XML, created from sources outside of the original PDF.

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

=head2 pdfsimple

 $converter->pdfsimple;

The "pdfsimple" method is a convenience method for quickly setting up
L<field2attribute> and L<field2texttype> mappings.  It is intended to handle
simple PDF-pages.  Currently, the following mappings are performed:

 - key "id" serialized as "filename" attribute
 - key "title" serialized as both attribute and texttype with same name

The "pdfsimple" method returns the object itself, so that it can be used in
one-liners.

=head2 preprocessor

 $converter->preprocessor( \&preprocess );
 $preprocessor = $converter->preprocessor;

The "preprocessor" method allows you to specify a subroutine that will be
executed before any of the other conversions take place on the input PDF.

When specified, the subroutine should be ready to expect the following input
parameters:

- reference to content hash

The content hash has been initialized with the "id" and "date" keys when the
preprocessor is called.  The preprocessor subroutine can make any changes to
the content hash that it seems fit.  An example of the use of a preprocessor
subroutine is the L<mhonarc> convenience method that extracts subject, from
and date information from the PDF which are stored in the content hash.

- PDF to be pre-processed

The second input parameter is the PDF that should be preprocessed.  The result
of this preprocessing should be adapted in place.

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

=head1 COPYRIGHT

Copyright (c) 1995-2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.nextrieve.com, the NexTrieve.pm and the other NexTrieve::xxx modules.

=cut
