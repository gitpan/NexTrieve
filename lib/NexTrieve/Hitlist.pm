package NexTrieve::Hitlist;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Hitlist::ISA = qw(NexTrieve);
$NexTrieve::Hitlist::VERSION = '0.03';

# Use all the submodules that we always need

use NexTrieve::Hitlist::Hit ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following subroutines are for creating objects

#------------------------------------------------------------------------

#  IN: 1 ordinal number of hit to obtain
# OUT: 1 instantiated Hit object

sub Hit {

# Obtain the object
# Obtain the class of the object
# If there is no dom for the search result yet, create it

  my $self = shift;
  my $class = ref($self);
  $self->_create_dom;

# Obtain the result
# Obtain the first hit in this hitlist
# Obtain the last hit in this hitlist

  my $result = $class.'::Result';
  my $firsthit = $self->{$result}->{'firsthit'};
  my $lasthit = $self->{$result}->{'displayedhits'}+$firsthit-1;

# Obtain the ordinal number of the hit to return
# Return the object from the list if it is within range

  my $ordinal = shift;
  return $self->{$class}->[$ordinal-$firsthit]
   if $ordinal >= $firsthit and $ordinal <= $lasthit;

# Add an error if we're still here
# Return an empty blessed object of the Hit class

  $self->_add_error(
   "Ordinal number is '$ordinal', must be between '$firsthit' and '$lasthit'" );
  return bless [],$class.'::Hit';
} #Hit

#------------------------------------------------------------------------

# OUT: 1..N list of all available Hit objects

sub Hits {

# Obtain the object
# Make sure that we have a DOM
# Return the list of Hit objects

  my $self = shift;
  $self->_create_dom;
  return @{$self->{ref($self)}};
} #Hits

#------------------------------------------------------------------------

# The following methods have to do with fields

#------------------------------------------------------------------------

# OUT: 1 administrative contact

sub admin { shift->_multi_value_ro( qw(Header admin) ) } #admin

#------------------------------------------------------------------------

# OUT: 1 displayed hits of hitlist

sub displayedhits {
 shift->_single_value_ro( qw(Result displayedhits) )} #displayedhits

#------------------------------------------------------------------------

# OUT: 1..N errors in result

sub errors { shift->_multi_value_ro( qw(Header error) ) } #errors

#------------------------------------------------------------------------

# OUT: 1 first hit of hitlist

sub firsthit { shift->_single_value_ro( qw(Result firsthit) ) } #firsthit

#------------------------------------------------------------------------

# OUT: 1 id of hitlist

sub id { shift->_single_value_ro( qw(Result id) ) } #id

#------------------------------------------------------------------------

# OUT: 1 last hit of hitlist

sub lasthit { shift->_single_value_ro( qw(Result lasthit) ) } #lasthit

#------------------------------------------------------------------------

# OUT: 1 total hits of hitlist

sub totalhits { shift->_single_value_ro( qw(Result totalhits) ) } #totalhits

#------------------------------------------------------------------------

# OUT: 1..N warnings in result

sub warnings { shift->_multi_value_ro( qw(Header warning) ) } #warnings

#------------------------------------------------------------------------

# The following subroutines are for creating dom and xml

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
   ::Header
   ::Result
   ::version
    )) {
    delete( $self->{$class.$_} ) if exists $self->{$class.$_};
  }
} #_delete_dom

#------------------------------------------------------------------------

sub _create_dom {

# Obtain the object
# Obtain the class of the object
# Return now if there is a DOM already

  my $self = shift;
  my $class = ref($self);
  return if exists $self->{$class.'::version'};

# Initialize the version and obtain local copy of the XML
# If there is XML to work with
#  Obtain the encoding and the XML to work with
#  Save the version
#  Return now if no version information found

  my $version; my $xml = $self->{$class.'::xml'} || '';
  if ($xml) {
    $self->{$class.'::encoding'} = $self->_encoding_from_xml( \$xml );
    $version = $self->_version_from_xml( \$xml,'ntv:hitlist' );
    return unless $version;

# Else (no XML to be processed)
#  Set the version to indicate we have a DOM
#  And return

  } else {
    $self->{$class.'::version'} = $self->NexTrieve->version;
    return;
  }

# If it is the initial version
#  Set the name of the result field
#  Obtain the header section
#  Set the result attributes

  if ($version eq '1.0') {
    my $resultfield = $class.'::Result';
    $xml =~ s#<header(.*?)>(.*?)</header>##s;
    $self->{$resultfield} = $self->_attributes2hash( $1 );

#  Save the header containers
#  Set the headers
#  Set the initial ordinal number value
#  Set the last hit value

    my $header = $2;
    $self->{$class.'::Header'} = $self->_containers2hash( $header );
    my $ordinal = $self->{$resultfield}->{'firsthit'};
    $self->{$resultfield}->{'lasthit'} =
     $ordinal + $self->{$resultfield}->{'displayedhits'} - 1;

#  Initialize the hitlist
#  Create the class of a single hit
#  While there are hits to be processed
#   Get the attributes for the hit
#   Save the containers of this hit
#   Set the ordinal number of this hit

    my $hitlist = [];
    my $hitclass = $class.'::Hit';
    while ($xml =~ s#<hit(.*?)>(.*?)</hit>##s) {
      my $hit = $self->_attributes2hash( $1,[qw(docid score)] );
      my $containers = $2;
      $hit->{'ordinal'} = $ordinal++;

#   Get the preview, if there is one
#   Get the containers of the attributes
#   Add an entry to the list for this hit as an object
#  Save the list in the object

      my $preview = $1 if $containers =~ s#<preview>(.*?)</preview>##s;
      my $attributes = $1 if $containers =~ s#<attributes>(.*?)</attributes>##s;
      push( @{$hitlist},
       bless [$hit,$preview,$self->_containers2hash( $attributes )],$hitclass );
    }
    $self->{$class} = $hitlist;

# Else (unsupported version)
#  Make sure there is no version information anymore
#  Set error value and return

  } else {
    delete( $self->{$class.'::version'} );
    $self->_add_error( "Unsupported version of <ntv:hitlist>: $version" );
    return;
  }

# Save the version information

  $self->{$class.'::version'} = $version;
} #_create_dom

#------------------------------------------------------------------------

# Is this routine needed? the DOM can only be created out of XML
# OUT: 1 <ntv:hitlist> XML

sub _create_xml {

# Obtain the object
# Make sure we have a DOM

  my $self = shift;
  $self->_create_dom;

# Obtain the class definition to be used
# Initialize version and XML
# Return now if error occurred

  my $class = ref($self);
  my ($version,$xml) = $self->_init_xml;
  return unless $version;

# Add the initial container
# If it is version 1.0
#  Add the <header> containers

  $xml .= $self->_init_container( 'hitlist' );
  if ($version eq '1.0') {
    my $result = $self->_hash2attributes( $self->{$class.'::Result'},
     [qw(firsthit displayedhits totalhits)] ) || '';
    $xml .= <<EOD;
EOD
    my $header = $self->_hash2containers( $self->{$class.'::Header'},
     [qw(warning error)] ) || '';
    $xml .= <<EOD if $result or $header;
<header$result>
$header</header>
EOD

#  For all of the hit containers
#   Obtain the hit attributes
#   Obtain the preview
#   Obtain the attribute containers

    foreach (@{$self->{$class}}) {
      my $hit = $self->_hash2attributes( $_->[0] ) || '';
      my $preview = $_->[1] || '';
      my $attributes = $self->_hash2containers( $_->[2] ) || '';

#   Add the XML for this hit

      $xml .= <<EOD;
<hit$hit>
<preview>$preview</preview>
<attributes>
$attributes</attributes>
</hit>
EOD
    }
  }

# Add the final part
# Return the complete XML, saving the XML in the object on the fly

  $xml .= <<EOD;
</ntv:hitlist>
EOD
  return $self->{$class.'::xml'} = $xml;
} #_create_xml

#-------------------------------------------------------------------------

# The following subroutines are for internal use only

#-------------------------------------------------------------------------

#  IN: 1 new tempfilename
# OUT: 1 old/current tempfilename

sub _tempfilename { shift->_class_variable( 'tempfilename',@_ ) } #_tempfilename

#-------------------------------------------------------------------------

# subroutines for standard Perl features

#------------------------------------------------------------------------

sub DESTROY { unlink( shift->_tempfilename || '' ) } #DESTROY

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Hitlist - handle the Hitlist specifications of NexTrieve

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $search = $ntv->Search( file | $resource | server:port | port );
 $query = $ntv->Query( | file | xml | {method => value} );
 $hitlist = $search->Hitlist( $query | xml | {method => value} );

=head1 DESCRIPTION

The Hitlist object of the Perl support for NexTrieve.  Do not create
directly, but through the Hitlist method of the NexTrieve object.

=head1 METHODS

The following methods are available to the NexTrieve::Hitlist object.

=head2 id

 $id = $hitlist->id;

=head2 firsthit

 $firsthit = $hitlist->firsthit;

=head2 lasthit

 $lasthit = $hitlist->lasthit;
 
=head2 displayedhits

 $displayedhits = $hitlist->displayedhits;

=head2 totalhits

 $totalhits = $hitlist->totalhits;

=head2 admin

 $admin = $hitlist->admin;

=head2 errors

 @error = $hitlist->errors;

=head2 warnings

 @warning = $hitlist->warnings;

=head2 Hits

 foreach $hit ($hitlist->Hits) {
 # display result here
 }

=head2 Hit

 foreach $ordinal ($firsthit..$lasthit) {
   $hit = $hitlist->Hit( $ordinal );
 # display result here
 }

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
