package NexTrieve::Docseq;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Docseq::ISA = qw(NexTrieve);
$NexTrieve::Docseq::VERSION = '0.37';

# Use all the Perl modules needed here

use NexTrieve::Document ();

# Initialize the list of texttype keys

my @texttypekey = qw(weight);

#  Initialize the recursive dispatch table

my %dispatch; %dispatch = (
 ''		=> sub {$_[0]},

 ARRAY		=> sub {
		        join('',
		         map {
                          &{$dispatch{ ref($_) }}( $_ )
                         } @{$_[0]} #map
		        ) #join
		       }, #sub

 HASH		=> sub {
		        join('',
		         map {
                          ($_ ? "<$_>" : '').
                          &{$dispatch{ ref($_[0]->{$_}) }}( $_[0]->{$_} ).
		          ($_ ? "</$_>" : '')
		         } keys %{$_[0]} #map
		        ) #join
		       }, #sub

 'NexTrieve::Document' => sub{shift->recode(shift)}, # must be quoted 5.005

 SCALAR		=> sub {${$_[0]}},
);

# Return true value for use

1;

#------------------------------------------------------------------------

# The following subroutines are methods to change the object

#------------------------------------------------------------------------

#  IN: 1..N chunks to be added (either value or reference or object)

sub add {

# Obtain the object
# Add the chunks to the object

  my $self = shift;
  my $class = ref($self);

# If we're streaming
#  For all of the data specified
#   Add to XML using the dispatcher

  if (exists( $self->{$class} )) {
    foreach my $chunk (@_) {
      $self->_pipe( \&{$dispatch{ref($chunk)} || sub {
       $self->_add_error( "Cannot handle chunk of type '".ref($chunk)."'" );
       return;} }($chunk,$self) || '' );
    }

# Else
#  Add the data to the object

  } else {
    push( @{$self->{$class.'::sequence'}},@_ );
  }
} #add

#------------------------------------------------------------------------

#  IN: 1 new setting of bare XML flag (default: no change)
# OUT: 1 current/old setting of bare XML flag

sub bare { shift->_class_variable( 'bare',@_ ) } #bare

#------------------------------------------------------------------------

sub done {

# Obtain the object
# Make sure the outer container is closed on all pipes unless inhibited

  my $self = shift;
  $self->_pipe( \<<EOD ) unless $self->bare;
</ntv:docseq>
EOD

# Obtain the class
# Close all of the pipes
# Remove any knowledge of the streams

  my $class = ref($self);
  close( $_ ) foreach @{$self->{$class}};
  delete( $self->{$class} );
} #done

#------------------------------------------------------------------------

# OUT: 1 always 'utf-8'

sub encoding {

# Obtain the object
# Add error if an attempt to change to something we don't want
# Return whatever we have for the object

  my $self = shift;
  $self->_add_error( "Cannot change encoding of Docseq object" ) if @_;
  return $self->{ref($self).'::encoding'} ||= 'utf-8';
} #encoding

#------------------------------------------------------------------------

#  IN: 1..N files to be processed
# OUT: 1 the object itself, handy for one-liners

sub files {

# Obtain the object
# Obtain the processor if any
# Obtain the NexTrieve object

  my $self = shift;
  my $processor = ref($_[0]) eq 'CODE' ? shift : '';
  my $ntv = $self->NexTrieve;

# If we have a processor routine
#  For all of the files specified
#   Obtain the data for that file
#   Reloop of nothing was fetched
#   Add documents for everything that is returned by the processor routine

  if ($processor) {
    foreach my $file (@_) {
      my $data = $self->slurp( $self->openfile( $file,'<' ) );
      next unless length($data);
      $self->add( $ntv->Document( $_ ) ) foreach &{$processor}( $data );
    }

# Else (no processor routine, just a simple copy)
#  Loop for all the parameters, create Document objects and add to the Docseq

  } else {
    $self->add( $ntv->Document->read_file( $_ ) ) foreach @_;
  }

# Return the object

  return $self;
} #files

#------------------------------------------------------------------------

#  IN: 1..N filenames or handles to stream to (none: to STDOUT)
# OUT: object itself

sub stream {

# Obtain the object
# Obtain the class definition to be used

  my $self = shift;
  my $class = ref($self);

# If there is streaming info already
#  Add error and return

  if (exists $self->{$class}) {
    return $self->_add_error(
     "Can only call method 'stream' once on an object" );
  }

# Make sure we have a DOM
# Obtain the version information and initial XML
# Return now if an error has occurred

  $self->_create_dom;
  my ($version,$xml) = $self->_init_xml;
  return $self unless $version;

# Initialize the handle
# Make sure we're streaming to STDOUT if nothing specified

  my $handle;
  push( @_,\*STDOUT ) unless @_;

# For all of the parameters specified
#  If it is not just a string (assume it is an object we can print to)
#   Save the handle
#  Else (assume it's a filename)
#   Attempt to open the file, return if failed
#  Save the handle in the object

  foreach (@_) {
    if (ref($_)) {
      $handle = $_;
    } else {
      return $self unless $handle = $self->openfile( $_,'>' );
    }
    push( @{$self->{$class}},$handle );
  }

# If it is version 1.0
#  Add the start of the container unless inhibited
#  Add the chunks that we have so far
#  Pipe them to whatever is needed
#  Delete the chunks that we had so far

  if ($version eq '1.0') {
    $xml .= $self->_init_container( 'docseq' ) unless $self->bare;
    $self->_add_chunks( \$xml );
    $self->_pipe( \$xml );
    delete( $self->{$class.'::sequence'} );
  }

# Return the object itself

  return $self;
} #stream

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
   ::encoding
   ::sequence
   ::version
    )) {
    delete( $self->{$class.$_} );
  }
} #_delete_dom

#------------------------------------------------------------------------

sub _create_dom {

# Obtain the object
# Save the class of the object
# Obtain the field for encoding
# Return now if there is a DOM already

  my $self = shift;
  my $class = ref($self);
  my $field = $class.'::encoding';
  return if exists $self->{$class.'::version'};

# Initialize the version, xml and attributes
# If there is XML to be processed
#  Obtain the encoding and the XML to work with
#  Recode the XML if it is not UTF-8 yet, setting field on the fly
#  Save the version and attributes
#  Return now if no version information found

  my ($version,$attributes); my $xml = $self->{$class.'::xml'} || '';
  if ($xml) {
    $self->{$field} = $self->_encoding_from_xml( \$xml );
    $xml = $self->recode( $self->{$field} = 'utf-8',$xml )
     if $self->{$field} ne 'utf-8';
    ($version,$attributes) = $self->_version_from_xml( \$xml,'ntv:docseq' );
    return unless $version;

# Else (no XML to be processed)
#  Set the version to indicate we have a DOM
#  And return

  } else {
    $self->{$class.'::version'} = $self->NexTrieve->version;
    return;
  }

# If it is version 1.0
#  Set the name of the field for the data
#  Extract all documents and put them in a list

  if ($version eq '1.0') {
    my $field = $class.'::sequence';
    $self->{$field} = [$xml =~ s#(<document>.*?</document>)\s*##sg];

#  If there is still stuff left (it should be all whitespace by now)
#   Add error
#   And return

    if ($xml =~ m#\S+#s) {
      $self->_add_error( "Extra data found in XML" );
      return;
    }

# Else (unsupported version)
#  Make sure there is no version information anymore
#  Set error value and return

  } else {
    delete( $self->{$class.'::version'} );
    $self->_add_error( "Unsupported version of <ntv:docseq>: $version" );
    return;
  }

# Save the version information

  $self->{$class.'::version'} = $version;
} #_create_dom

#------------------------------------------------------------------------

# OUT: 1 <ntv:docseq> XML

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
#  Add the start of the container unless inhibited
#  Add all the chunks

  if ($version eq '1.0') {
    $xml .= $self->_init_container( 'docseq' ) unless $self->bare;
    $self->_add_chunks( \$xml );
  }

# Add the final part
# Return the complete XML, saving the XML in the object on the fly

  $xml .= <<EOD;
</ntv:docseq>
EOD
  return $self->{$class.'::xml'} = $xml;
} #_create_xml

#------------------------------------------------------------------------

# The following subroutines are for internal use only

#------------------------------------------------------------------------

#  IN: 1 reference to xml to add to

sub _add_chunks {

# Obtain the object
# Obtain the reference to the XML

  my $self = shift;
  my $refxml = shift;

# For all of the data collected
#  Add to XML using the dispatcher

  foreach my $chunk (@{$self->{ref($self).'::sequence'}}) {
    $$refxml .= &{$dispatch{ref($chunk)} || sub {
     $self->_add_error( "Cannot handle chunk of type '".ref($chunk)."'" );
     return;} }($chunk,$self) || '';
  }
} #_add_chunks

#------------------------------------------------------------------------

#  IN: 1 reference to data to be piped

sub _pipe {

# Obtain the object
# For all of the streams
#  Send whatever was indicated to that stream

  my $self = shift;
  foreach my $handle (@{$self->{ref($self)}}) {
    print $handle ${$_[0]} || '';
  }
} #_pipe

#------------------------------------------------------------------------

# The following subroutines are for standard Perl object functionality

#------------------------------------------------------------------------

sub DESTROY { goto &done } #DESTROY

#------------------------------------------------------------------------

1;
__END__

=head1 NAME

NexTrieve::Docseq - handling a NexTrieve Document Sequence

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $docseq = $ntv->Docseq( | file | xml | {method => value} );

 # non-streaming mode, XML built in memory
 $docseq->add( data );
 $docseq->add( moredata );
 $docseq->add( stillmoredata );
 $docseq->write_file( filename );

 #streaming-mode, XML sent to stream immediately
 $docseq->stream( handle | filename );
 $docseq->add( data );
 $docseq->add( moredata );
 $docseq->add( stillmoredata );
 $docseq->done; # or let $docseq go out of scope

=head1 DESCRIPTION

The Docseq object of the Perl support for NexTrieve.  Do not create
directly, but through the Docseq method of the NexTrieve object.

=head1 METHODS

The following methods are available to the NexTrieve::Docseq object.

=head2 add

 $docseq->add( $data | \$data | [$data] | {container => $data} | $document );

The "add" method allows you to add data to a document sequence.  Each input
parameter can be one of the following:

- scalar value containing XML in UTF-8

 $docseq->add( "<document><attributes><id>1</id></attributes></document>" );

- reference to a scalar value containing XML in UTF-8

 $docseq->add( \"<document><attributes><id>1</id></attributes></document>" );

- reference to a list of values containing XML in UTF-8

 $docseq->add( ["<document><attributes><id>1</id></attributes></document>"] );

- NexTrieve::Document object

 my $document = $ntv->Document( {attribute => [qw(id 1)]} );
 $docseq->add( $document ); # calls "xml" method on object

- reference to hash, containing any of above, key = name of container, value = string encoded in UTF-8

 $docseq->add( {document => {attributes => {id => 1}}} );

All of the above are equivalent ways of doing the same thing.

All forms of expressions can be mixed: everything will be expanded until it is
a scalar value which can be added to the XML of the document sequence.

Please note that you usually do not call the "add" method directly, but that
this rather happens by customized versions of the "Docseq" method in various
other modules.

=head2 bare

 $ntvobject->bare( true | false );
 $bare = $ntvobject->bare;

The XML generated by the NexTrieve family, consists of an outer container
indicating the version of NTVML the XML conforms to.  In some cases (e.g. when
creating document sequences to be merged together later) it may be desirable
to have the outer container to be absent, i.e. to have the XML be created
"bare".  You can achieve this by calling the "bare" method with a true value
before the XML is generated.

=head2 done

 $docseq->done; # not really needed, DESTROY on object does same

The "done" method is only needed when the NexTrieve::Docseq is in L<stream>ing
mode.  It stops the streaming by closing the <ntv:docseq> container and closing
the handle that was used for writing to the stream.

Calling the "done" method is not strictly necessary.  As soon as the object
goes out of scope, a call to "done" is done autmatically.

=head2 files

 $docseq->files( <files.xml> );
 $docseq->files( \&processor,<files.anydata> );

The "files" method allows you to add one or more external files containing
data to be added to a document sequence.  These could be pre-made XML files,
or files containing any other type of data that need to be processed first
before being added to the document sequence.

The first (optional) input parameter specifies a reference to a processor
routine that will take the contents of the file as its input parameter.  It
should return zero or more XML-containers, one for each document to be added
to the document sequence.

The other input parameters specify the names of the files that should be
read and passed into the document sequence.

The Docseq object itself is returned by this method, which makes it handy
for one-liners.

=head2 stream

 open( $handle,">filename" );
 $docseq->stream( $handle );

 $docseq->stream( filename1,filename2 );

The "stream" method can be called to cause the document sequence to be streamed
to a file or an external process (such as the NexTrieve indexer).

Each input parameter can either be a filename or an already opened handle.
If it is a filename, the file is opened for writing as a new file, losing any
contents that were stored there previously.

Please note that NexTrieve::Index module allows you to create a
NexTrieve::Docseq object that automatically streams to the NexTrieve indexer.
See the NexTrieve::Index module for more information.

=head2 xml

 $docseq->xml( $xml );
 $xml = $docseq->xml;

The "xml" method can only be used if the NexTrieve::Docseq object is B<not> in
streaming mode.  You can either use it to set the complete XML of the document
sequence or have it returned to you.  Only the latter seems to be a sensible
thing to do.

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
