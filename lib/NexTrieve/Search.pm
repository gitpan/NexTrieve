package NexTrieve::Search;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Search::ISA = qw(NexTrieve);
$NexTrieve::Search::VERSION = '0.02';

# Use other NexTrieve modules that we need always

use NexTrieve::Hitlist ();
use NexTrieve::Resource ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 server:port or filename or XML or Resource or Daemon object
#      3 reference to method/value pairs

sub _new {

# Obtain the class of the object
# Attempt to create the base object

  my $class = shift;
  my $self = $class->SUPER::_new( shift );

# Handle the resource specification if there is any
# Handle any method/value pair setting

  $self->Resource( ref($_[0]) eq 'NexTrieve::Daemon' ?
   shift->serverport : shift ) if @_;
  $self->Set( shift ) if @_;

# Return the object

  return $self;
} #_new

#------------------------------------------------------------------------

# OUT: 1 flag whether associated NexTrieve executable installed and executable

sub executable { -x NexTrieve->new->NexTrievePath.'/ntvsearch' } #executable

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 new resource specification (server:port or filename or xml or object)
# OUT: 1 current/old resource specification

sub Resource {

# Obtain the object
# Obtain the resource specification
# Return now as an ordinary Resource handler if it is not a server:port spec

  my $self = shift;
  my $resource = shift || '';
  return $self->SUPER::Resource( $resource )
   unless $resource =~ m#^(?:([\w\_\.]+):)?(\d+)$#;

# Obtain the name of the field
# Obtain the current setting
# Return the resource specification

  my $field = ref($self).'::Resource';
  my $old = $self->{$field};
  $self->{$field} = $resource;
  return $old;
} #Resource

#------------------------------------------------------------------------

#  IN: 1 query as xml or Query object
#      2 name of file to store hitlist in (default: none)
# OUT: 1 instantiated NexTrieve::Hitlist object

sub Hitlist {

# Obtain the object
# Obtain the class of the object
# Obtain the NexTrieve object
# Create a new Hitlist object
# Obtain the query

  my $self = shift;
  my $class = ref($self);
  my $ntv = $self->NexTrieve;
  my $hitlist = $ntv->Hitlist;

# Obtain the XML of the query
# Obtain the type of object of the query
# If it is a Query object
#  Convert to XML

  my $queryxml = shift;
  my $refqueryxml = ref($queryxml);
  if ($refqueryxml eq 'NexTrieve::Query') {
    $queryxml = $queryxml->write_string;

# Elseif it is an objecty of some sort
#  Return hitlist, indicating an error
# Elseif there is no query at all
#  Return hitlist, indicating an error

  } elsif ($refqueryxml) {
    return $hitlist->_add_error(
     "Must specify a NexTrieve::Query, not a '$refqueryxml'" );
  } elsif (!$queryxml) {
    return $hitlist->_add_error( "Must specify a query" );
  }

# Obtain the filename to store in

  my $filename = shift;

# Obtain copy of the Resource
# Initialize the XML of the hitlist
# If we have a Query object
#  Obtain the command specification, saving it in the object on the fly
#  Return now if there is no command

  my $resource = $self->{$class.'::Resource'};
  my $hitlistxml;
  if (ref($resource)) {
    my $command = $self->{$class.'::command'} =
     $self->_command_log( 'ntvsearch' );
    return $hitlist unless $command;

#  Save flag for using a temporary file
#  Set temporary filename if we have a temporary file only
#  Save the filename (is tempfile if not specified explicitely)

    my $temp = !$filename;
    $hitlist->_tempfilename($filename=$self->tempfilename('hitlist')) if $temp;
    $hitlist->filename( $filename );

#  Open the pipe to the search program
#  Tell it to go searching
#  Close the handle
#  Read back the file if it is a temporary file
#  Return the hitlist object

    my $handle = $self->openfile( "|$command >$filename" );
    print $handle $queryxml;
    close( $handle );
    $hitlist->read_file if $temp;
    return $hitlist;

# Elseif there is a server/port combination
#  If we want the file directly written
#   Do that and return

  } elsif ($resource) {
    if (!defined(wantarray) and $filename) {
      $hitlist->ask_server_port_file( $resource,$queryxml,$filename );
      return;
    }

#  Obtain the hitlist XML
#  Write it to a file if necessary
#  Return the object

    $hitlist->read_string( $hitlist->ask_server_port( $resource,$queryxml ) );
    $hitlist->write_file( $filename ) if $filename;
    return $hitlist;
  }

# Return error (no resource specification)

  return $hitlist->_add_error( 'Must have a resource specification' );
} #Hitlist

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Search - handle searching with NexTrieve

=head1 SYNOPSIS

 use NexTrieve;
 die unless NexTrieve::Search->executable;

 $ntv = NexTrieve->new( | {method => value} );

 # using collections
 $collection = $ntv->Collection( path );
 $search = $collection->Search( mnemonic, | indexname );

 # using direct access
 $resource = $ntv->Resource( | file | xml | {method => value} );
 $search = $ntv->Search( | file | $resource | host:port | port );

 $query = $ntv->Query( file | xml | {method => value} );

 # using Perl DOM
 $hitlist = $search->Hitlist( file | xml | $query );
 foreach ($hitlist->Hits) {

 # using external file (e.g. for XSLT transformations)
 $search->Hitlist( file | xml | $query, $filename );
 system( "xsltproc stylesheet.xsl $filename" );

=head1 DESCRIPTION

The Search object of the Perl support for NexTrieve.  Do not create
directly, but through the Search method of the NexTrieve or the
NexTrieve::Collection object.

=head1 CLASS METHODS

These methods are available as class methods.

=head2 executable

 $executable = NexTrieve::Search->executable;

=head1 METHODS

These methods are available to the NexTrieve::Search object.

=head2 Hitlist

 $hitlist = $search->Hitlist( $query );

=head2 Resource

 $resource = $search->Resource( | file | xml | {method => value} );

=head2 indexdir

 $search->indexdir( $indexdir );
 $indexdir = $search->indexdir;

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
