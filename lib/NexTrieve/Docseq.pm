package NexTrieve::Docseq;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Docseq::ISA = qw(NexTrieve);
$NexTrieve::Docseq::VERSION = '0.01';

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

 NexTrieve::Document => sub {$_[0]->write_string},

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
       $self->_add_error( "Cannot handle chunk of type ".ref($_[0]) );
       return;} }($chunk) || '' );
    }

# Else
#  Add the data to the object

  } else {
    push( @{$self->{$class.'::sequence'}},@_ );
  }
} #add

#------------------------------------------------------------------------

#  IN: 1..N filenames or handles to stream to
# OUT: object itself

sub stream {

# Obtain the object
# Obtain the class definition to be used

  my $self = shift;
  my $class = ref($self);

# If there is streaming info already
#  Add error and return
# Elseif there are no parameters specified
#  Add error and return

  if (exists $self->{$class}) {
    return $self->_add_error(
     "Can only call method 'stream' once on an object" );
  } elsif (!@_) {
    return $self->_add_error( "Must specify at least one stream" );
  }

# Make sure we have a DOM
# Obtain the version information and initial XML
# Return now if an error has occurred

  $self->_create_dom;
  my ($version,$xml) = $self->_init_xml;
  return $self unless $version;

# Initialize the handle
# For all of the parameters specified
#  If it is not just a string (assume it is an object we can print to)
#   Save the handle
#  Else (assume it's a filename)
#   Attempt to open the file, return if failed
#  Save the handle in the object

  my $handle;
  foreach (@_) {
    if (ref($_)) {
      $handle = $_;
    } else {
      return $self unless $handle = $self->openfile( $_,'>' );
    }
    push( @{$self->{$class}},$handle );
  }

# If it is version 1.0
#  Add the start of the container
#  Add the chunks that we have so far
#  Pipe them to whatever is needed
#  Delete the chunks that we had so far

  if ($version eq '1.0') {
    $xml .= $self->_init_container( 'docseq' );
    $self->_add_chunks( \$xml );
    $self->_pipe( \$xml );
    delete( $self->{$class.'::sequence'} );
  }

# Return the object itself

  return $self;
} #stream

#------------------------------------------------------------------------

sub done {

# Obtain the object
# Make sure the outer container is closed on all pipes

  my $self = shift;
  $self->_pipe( \<<EOD );
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
#  Add the start of the container
#  Add all the chunks

  if ($version eq '1.0') {
    $xml .= $self->_init_container( 'docseq' );
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
     $self->_add_error( "Cannot handle chunk of type ".ref($_[0]) );
     return;} }($chunk) || '';
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
    print $handle ${$_[0]};
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

The following methods are available to the NexTrieve::Docseq object, apart
from the ones inherited from the NexTrieve module.

=head2 stream

 open( $handle,">filename" );
 $docseq->stream( $handle );

 $docseq->stream( filename );

=head2 add

 $docseq->add( $data | \$data | [$data] | {container => $data} | $document );

=head2 done

 $docseq->done # not really needed, DESTROY on object does same

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
