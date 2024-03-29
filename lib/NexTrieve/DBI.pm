package NexTrieve::DBI;

# Set modules to inherit from
# Set version information
# Make sure we do everything by the book from now on

@ISA = qw(NexTrieve);
$VERSION = '0.41';
use strict;

# Use the modules that are needed always

use NexTrieve::Docseq ();
use NexTrieve::Document ();

# Satisfy -require-

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 Docseq object (optional)
#      2 DBI statement handle
#      3 name of key to serve as "id" (default: id method)
#      4 name of key to serve as default text (default: text method)
#      5 normalization method (default: normalize method)
#      6 name of method to call for hashref (default: fetch method)
# OUT: 1 instantiated Docseq object

sub Docseq {

# Obtain the object
# Obtain the Docseq object if there is any, create new if none available

  my $self = shift;
  my $docseq = ref($_[0]) eq 'NexTrieve::Docseq' ?
   shift : $self->NexTrieve->Docseq;

# Obtain the statement handle
# Return now if none available

  my $sth = shift;
  return $docseq unless $sth;

  my $id = shift || $self->id;
  my $text = shift || $self->text;
  my $normalize = shift || $self->normalize;
  my $method = shift || $self->fetch;

  while (my $content = $sth->$method) {
    $docseq->add( $self->Document( $content,$id,$text,$normalize ) );
  }

# Return the finalized document

  return $docseq;
} #Docseq

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 new name in $sth for id field (default: 'id')
# OUT: 1 current/old name in $sth for id field

sub id { shift->_class_variable( 'id',@_ ) || 'id' } #id

#------------------------------------------------------------------------

#  IN: 1 new name for fetch method (default: 'fetchrow_hashref')
# OUT: 1 current/old name for fetch method

sub fetch { shift->_class_variable( 'fetch',@_ ) || 'fetchrow_hashref' } #fetch

#------------------------------------------------------------------------

#  IN: 1 new name for normalization method (default: 'ampersandize')
# OUT: 1 current/old name of normalization method

sub normalize {
 shift->_class_variable( 'normalize',@_ ) || 'ampersandize' } #normalize

#------------------------------------------------------------------------

#  IN: 1 new name in $sth for text field (default: 'text')
# OUT: 1 current/old name in $sth for text field

sub text { shift->_class_variable( 'text',@_ ) || 'text' } #text

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::DBI - convert DBI statement handle to NexTrieve Document sequence

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );

 $converter = $ntv->DBI( | {method => value} );

 $docseq = $converter->Docseq( $ntv->Index( $resource )->Docseq,$sth );
 $docseq->done;

=head1 DESCRIPTION

The DBI object of the Perl support for NexTrieve.  Do not create
directly, but through the DBI method of the NexTrieve object;

The "dbi2ntvml" script is basically a directly configurable and executable
wrapper for the NexTrieve::DBI module.

=head1 CONVERSION PROCESS

The conversion of a statementb handle consists of basically three phases:

 - creating the NexTrieve::DBI object
 - setting the appropriate parameters
 - serializing the content hash to XML

More specifically, the following steps are performed.

=over 2

=item create NexTrieve::DBI object

You must create the NexTrieve::DBI object by calling the "DBI" method of the
NexTrieve object.  You can set any parameters directly with the creation of
the object by specifying a hash with method names and values.  Or you can set
the parameters later by calling the methods on the object.

=item setting parameters

After the object is created, you will have to decide which fields in the
statement handle should be used as L<id> and L<text>.  You will also have to
decide which fields of the content hash should appear as what attributes (see
L<field2attribute>) and/or texttypes (see L<field2texttype>).

You should also think about extra attributes (see L<extra_attribute>) and/or
texttypes (see L<extra_texttype>) that should be added to the XML that are not
part of the statement handle.  And you should consider if any conversions
should be done on the information that is destined to become an attribute (see
L<attribute_processor>) or a texttype (see L<texttype_processor>), before
they are actually serialized into XML.

By setting up all of this information, you may find it handy to use the
L<Resource> method for setting up the basic resource-file that could be used by
NexTrieve to index the XML generated by these settings.

=item serializing the XML

When all of this is done, all of the information in the content hash as well
as the remaining text (from the original HTML) are fed to a generic
serialization routine that is also used by the NexTrieve::RFC822 and
NexTrieve::HTML modules.

This serialization routine looks for any extra attributes and/or texttypes and
processor routines, executes them in the correct order and generates the XML
for the record that was provided on input.

If you want to access the XML, you can call the L<xml> method, which is
inherited from the NexTrieve module.

=back

=head1 OBJECT CREATION METHODS

These methods create objects from the NexTrieve::DBI object.

=head2 Docseq

 $docseq = $converter->Docseq( $sth,'id','text','ampersandize','fetchrow_hashref' );

 $index = $ntv->Index( $resource );
 $converter->Docseq( $index->Docseq,$sth,'id','text','ampersandize','fetchrow_hashref' );

The Docseq method allows you to create a NexTrieve document sequence object
(or NexTrieve::Docseq object) out of a DBI statement handle.  This can either
be used to be directly indexed by NexTrieve (through the NexTrieve::Index
object) or to create the XML of the document sequence in a file for indexing
at a later stage.

The first (optional) input parameter is an (already existing)
NexTrieve::Docseq object that should be used.  This can either be a special
purpose NexTrieve::Docseq object as created by the NexTrieve::Index module,
or a NexTrieve::Docseq object that was created earlier on which a second
run of a statement handle needs to be added.

The second input parameter specifies the DBI statement handle on which the
L<fetch> method should be executed.

The third input parameter specifies the name of the field that should be
considered to contain the "id" of the record.  The default can be specified
with the L<id> method.  If no default was specified previously, the name "id"
will be assumed.

The fourth input parameter specifies the name of the field that should be
considered to contain the "text" of the record.  The default can be specified
with the L<text> method.  If no default was specified previously, the name
"text" will be assumed.

The fifth input parameter specifies the name of the normalization routine that
should be used to create valid XML.  The default can be specified with the
L<normalize> method.  If no default was specified previously, the name
"ampersandize" will be assumed.

The sixth input parameter specifies the name of the field that should be
considered to contain the name of the method to perform the fetch for each
record.  The default can be specified with the L<fetch> method.  If no default
was specified previously, the method "fetchrow_hashref" will be assumed.

For more information, see the NexTrieve::Docseq module.

=head2 Resource

 $resource = $converter->Resource( | {method => value} );

The "Resource" method allows you to create a NexTrieve::Resource object from
the internal structure of the NexTrieve::DBI.pm object.  More specifically,
it takes the information as specified with the L<extra_attribute,
L<field2attribute>, L<extra_texttype> and L<field2texttype> methods and creates
the <indexcreation> section of the NexTrieve resource file as specified on
http://www.nextrieve.com/usermanual/2.0.0/ntvresourcefile.stm .

For more information, see the documentation of the NexTrieve::Resource module
itself.

=head1 OTHER METHODS

These methods change aspects of the NexTrieve::DBI object.

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
added to the serialized XML, created from sources outside of the original
statement handle.

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
statement handle.

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

=head2 fetch

 $converter->fetch( 'fetchrow_hashref' );
 $fetch = $converter->fetch;

The "fetch" method indicates the name of the method that should be executed
on the statement handle to obtain a reference to a hash.  By default, the name
used is "fetchrow_hashref", which is the name of the method used by the Perl
"DBI" module for returning a reference to a hash for the next record from a
statement handle.

You only need to call this method if the statement handle that you pass to the
L<Document> method is not capable of processing the "fetchrow_hashref" method.

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

=head2 id

 $converter->id( 'id' );
 $id = $converter->id;

The "id" method specifies which field in the reference to the hash returned
by the L<fetch> method, should be considered to be the "id" identifying this
particular record.  By default, the name "id" is assumed.

=head2 normalize

 $converter->normalize( 'ampersandize' );
 $normalize = $converter->normalize;

Before any text that is obtained from the statement handle is allowed to be
inserted into XML, it needs to be normalized so that no invalid XML can be
generated.  There are two modes of normalization available:

 - ampersandize

This should be used when the text is considered to be "normal" text without
HTML or XML entities.

 - normalize

This should be used when the text is considered to be "HTML" like in the sense
that it may contain HTML or XML entities.

By default, "ampersandize" is assumed.

=head2 text

 $converter->text( 'text' );
 $text = $converter->text;

The "text" method specifies which field in the reference to the hash returned
by the L<fetch> method, should be considered to be the "text".  The content of
this field will be removed from the content hash before being processed.  By
default, the name "text" is assumed.

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
