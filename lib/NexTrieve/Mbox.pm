package NexTrieve::Mbox;

# Set modules to inherit from
# Set version information
# Make sure we do everything by the book from now on

@ISA = qw(NexTrieve);
$VERSION = '0.41';
use strict;

# Use other NexTrieve modules that we need always

use NexTrieve::RFC822 ();

# Initialize the new message delimiter

my $newmessagedelimiter = '^From ';

# Initialize mailbox, offset and length (we need to be able to reference them)

my $mailbox;
my $offset;
my $length;

# Satisfy -require-

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 reference to parameter hash to be passed to RFC822
# OUT: 1 instantiated NexTrieve::Mbox object

sub _new {

# Create an object of the right class
# Create an RFC822 object in there if any parameters are specified
# Return the object

  my $self = shift->SUPER::_new( shift );
  $self->RFC822( @_ ) if @_;
  return $self;
} #_new

#------------------------------------------------------------------------

#  IN: 1 Docseq object (optional)
#      2..N filenames of mboxes to process
# OUT: 1 instantiated Docseq object

sub Docseq {

# Obtain the object
# Obtain the Docseq object if there is any, create new if none available
# Obtain the RFC822 object to work with

  my $self = shift;
  my $docseq = ref($_[0]) eq 'NexTrieve::Docseq' ?
   shift : $self->NexTrieve->Docseq;
  my $rfc822 = $self->RFC822;

# Obtain the Archive specification
# Change into a handle for appending if we have one and it is a filename

  my $archive = $self->archive;
  $archive = $self->openfile( $archive,'>>' ) if $archive and !ref($archive);

# Obtain the conceptualmailbox name
# Obtain the base offset if there is any
# Initialize the offset

  my $conceptualmailbox = $self->conceptualmailbox;
  my $baseoffset = $self->baseoffset || 0;
  $offset = $conceptualmailbox ? $baseoffset : 0;

# For all of the mailboxes to be handled
#  Attempt to open the file
#  Reloop now if failed
#  Set mailbox name
#  Initialize linenumber

  foreach my $filename (@_) {
    my $handle = $self->openfile( $filename,'<' );
    next unless $handle;
    $mailbox = $conceptualmailbox || $filename;
    my $linenumber = 0;

#  (Re-)Initialize the offset
#  Get the first line
#  While we're at a new message boundary
#   Initialize the message
#   Save the starting linenumber
#   While we're _not_ at a message boundary, fetching new line on the fly
#    Increment line number
#    Add line to message
#    Write this message to the archive if we're archiving

    $offset = 0 unless $conceptualmailbox;
    my $line = <$handle>;
    while (defined($line) and $line =~ m#$newmessagedelimiter#o) {
      my $message = $line;
      my $start = $linenumber++;
      while (defined($line = <$handle>) and $line !~ m#$newmessagedelimiter#o) {
        $linenumber++;
        $message .= $line;
      }
      print $archive $message if $archive;

#   Calculate the length of the message
#   Create a document from the message
#   Set the source of the document
#   Add to the docseq
#   Step up the offset

      $length = length( $message );
      my $document = $rfc822->Document( $message,'' );
      $document->{ref($document).'::SOURCE'} = "$filename, line $start";
      $docseq->add( $document );
      $offset += $length;
    }
  }

# Update the baseoffset if we have a conceptualmailbox
# Return the finalised document sequence

  $self->baseoffset( $baseoffset+$offset ) if $conceptualmailbox;
  return $docseq;
} #Docseq

#------------------------------------------------------------------------

#  IN: 1 reference to hash with any extra parameters
# OUT: 1 instantiated Resource object

sub Resource { shift->RFC822->Resource( @_ ) } #Resource

#------------------------------------------------------------------------

#  IN: 1 reference to method/value pair hash
# OUT: 1 instantiated RFC822 object

sub RFC822 {

# Obtain the object
# Create the field name of the RFC822 object

  my $self = shift;
  my $field = ref($self).'::rfc822';

# If there is an object already
#  Execute whatever we want to execute on it if there is anything
#  Return the current object

  if (exists $self->{$field}) {
    $self->{$field}->Set( @_ ) if @_;
    return $self->{$field};
  }

# Create a new RFC822 object
# Add the extra attributes to that 

  my $rfc822 = $self->NexTrieve->RFC822( @_ );
  $rfc822->extra_attribute(
   [\$mailbox,qw(mailbox string key-duplicate 1)],
   [\$offset,qw(offset number notkey 1)],
   [\$length,qw(length number notkey 1)],
  );

# Return the newly created object, saving it on the fly

  return $self->{$field} = $rfc822;
} #RFC822

#------------------------------------------------------------------------

# Following methods change the object

#------------------------------------------------------------------------

#  IN: 1 new archive name
# OUT: 1 current/old archive name

sub archive { shift->_class_variable( 'archive',@_ ) } #archive

#------------------------------------------------------------------------

#  IN: 1 new baseoffset
# OUT: 1 current/old baseoffset

sub baseoffset { shift->_class_variable( 'baseoffset',@_ ) } #baseoffset

#------------------------------------------------------------------------

#  IN: 1 new conceptualmailbox name
# OUT: 1 current/old conceptualmailbox name

sub conceptualmailbox {

# Obtain the object
# Remove base offset if a new conceptualmailbox is specified
# Return the result of setting/returning

  my $self = shift;
  delete( $self->{ref($self).'::baseoffset'} ) if @_;
  return $self->_class_variable( 'conceptualmailbox',@_ )
} #conceptualmailbox

#------------------------------------------------------------------------

# Internal subroutines go here

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Mbox - convert Unix mailbox to NexTrieve Document sequence

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );

 $converter = $ntv->Mbox( | {method => value} );

 $docseq = $converter->Docseq( $ntv->Index( $resource )->Docseq,<*.mbox> );
 $docseq->done;

=head1 DESCRIPTION

The Mbox object of the Perl support for NexTrieve.  Do not create
directly, but through the Mbox method of the NexTrieve object;

The NexTrieve::Mbox module is basically a wrapper around the NexTrieve::RFC822
object.  For more information about handling messages, please check the
documentation of the NexTrieve::RFC822 module.

The "mailbox2ntvml" script is basically a directly configurable and executable
wrapper for the NexTrieve::Mbox module.

=head1 CONVERSION PROCESS

The conversion process of the NexTrieve::Mbox module basically creates a
NexTrieve::RFC822 object inside of itself, that is used to describe the
format of the NexTrieve::Document XML that should be generated from each
message in a mailbox.

Before commencing with indexing, three attributes are added to the
NexTrieve::RFC822 object.  They are:

- mailbox string key-duplicate 1

Either the name of the Unix mailboxfile, or the string specified with the
L<conceptualmailbox> method.

- offset number notkey 1

The offset of the message in the (conceptual) mailbox.  Each time a message
is finished processing, its length is added to the internally kept offset
value.

- length number notkey 1

The length of the message in the (real) mailbox.

If you are not using the L<conceptualmailbox> feature, then the combination
of the mailbox, offset and length attributes (as e.g. returned as attributes
in a hit of a hitlist) can be directly applied to obtain a copy of the original
message.

If the L<conceptualmailbox> feature is used, you are a little bit more on your
own: you, as a developer, knows how the conceptualmailbox string maps to a
real file or database entry.

The start of a new message in a mailbox is indicated by the string "From " at
the beginning of a line.  An attempt is made to even handle broken mailboxes,
that do not contain complete messages and/or attachments.  Depending on the
brokenness of the mailbox, none to all messages might actually be ignored in
the conversion process.

=head1 OBJECT METHODS

The following methods return objects.

=head2 Docseq

 $docseq = $converter->Docseq( @mbox );
 $docseq->write_file( filename );

 $index = $ntv->Index( $resource );
 $converter->Docseq( $index->Docseq,@mbox );

The Docseq method allows you to create a NexTrieve document sequence object
(or NexTrieve::Docseq object) out of the messages in one or more Unix
mailboxes.  This can either be used to be directly indexed by NexTrieve
(through the NexTrieve::Index object) or to create the XML of the document
sequence in a file for indexing at a later stage.

The first (optional) input parameter is an (already existing)
NexTrieve::Docseq object that should be used.  This can either be a special
purpose NexTrieve::Docseq object as created by the NexTrieve::Index module,
or a NexTrieve::Docseq object that was created earlier on which a second
run of messages from mailboxes need to be added.

The rest of the input parameters indicate the mailboxes that should be
indexed.  These can either be just filenames, or URL's in the form:
file://directory/mail.mbx  or  http://server/mail.mbx.

For more information, see the NexTrieve::Docseq module.

=head2 Resource

 $resource = $converter->Resource( | {method => value} );

The "Resource" method allows you to create a NexTrieve::Resource object from
the internal structure of the NexTrieve::L<RFC822>.pm object that lives inside
of the NexTrieve::Mbox object.

For more information, see the documentation of the NexTrieve::RFC822 and
NexTrieve::Resource modules itself.

=head2 RFC822

 $converter->RFC822( {method => value} ;
 $rfc822 = $converter->RFC822;

The "RFC822" method allows you to access the NexTrieve::RFC822 object that
lives inside of the NexTrieve::Mbox object and which is created when the
NexTrieve::Mbox object is created.

To facilitate access, a reference to a method-value pair hash can be
specified as the input parameter.

For more information, see the documentation of the NexTrieve::RFC822 module
itself.

=head1 OTHER METHODS

The following methods change aspects of the NexTrieve::Mbox object.

=head2 archive

 $converter->archive( $archive );
 $archive = $converter->archive;

Although the functionality of the NexTrieve::Mbox module is to just be a
filter, the "archive" method allows you to do some message archive management
with this module as well.

The input parameter specifies the name of the file to which all of the
messages that are read (which could be from multiple mailbox or rfc822 files)
are added at the end.  Combined with the L<conceptualmailbox> method and the
L<baseoffset> method, a basic email management system can be made.

=head2 baseoffset

 $converter->baseoffset( $offset | -e filename ? -s _ : 0 );
 $baseoffset = $converter->baseoffset;

The "baseoffset" method can only be used if the L<conceptualmailbox> method
is also used.  It specifies the value of the "offset" attribute of the first
message to be read from the mailbox.  The value you typically specify is the
size of the file in which the messages will eventually be stored, which you
can e.g. specify with the L<archive> method.

=head2 conceptualmailbox

 $converter->conceptualmailbox( filename );
 $conceptualmailbox = $converter->conceptualmailbox;

The "conceptualmailbox" method allows you to specify the value that should
be saved in the "mailbox" attribute of all messages processed by this
NexTrieve::Mbox object.  When used with the L<archive> method, it is usually
the relative filename of the mailbox archive (where the archive filename is
the absolute filename).

If a conceptual mailbox is specified, all messages being processed are
considered to be part of the same (virtual) mailbox.  This means that the
offset attribute value is B<not> reset when another mailbox is processed.

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
