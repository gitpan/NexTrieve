package NexTrieve::Search;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Search::ISA = qw(NexTrieve);
$NexTrieve::Search::VERSION = '0.32';

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
   shift->serverport : (ref($_[0]) eq 'ARRAY' ? @{shift(@_)} : shift) ) if @_;
  $self->Set( shift ) if @_;

# Return the object

  return $self;
} #_new

#------------------------------------------------------------------------

# OUT: 1 flag: whether it should work or not
#      2 expiration date of license ('' if not known)
#      3 software version
#      4 database version
#      5 whether threaded or no

sub executable { NexTrieve->executable( 'ntvsearch' ) } #executable

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

#  Tell it to go searching
#  Read back the file if it is a temporary file
#  Return the hitlist object

    $self->splat( $self->openfile( "|$command >$filename" ),$queryxml );
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

The NexTrieve::Search object either accesses a NexTrieve search service through
the "ntvsearch" program (as described on
http://www.nextrieve.com/usermanual/2.0.0/ntvsearch.stm ) or through a NexTrieve
server process using the "ntvsearchd" program (as described on
http://www.nextrieve.com/usermanual/2.0.0/ntvsearchd.stm ), previously started
by a NexTrieve::Daemon object.

=head1 CLASS METHODS

These methods are available as class methods.

=head2 executable

 $executable = NexTrieve::Daemon->executable;
 ($program,$expiration,$software,$database) = NexTrieve::Search->executable;

Return information about the associated NexTrieve program "ntvsearch".  Please
note that calling this method only makes sense if the search service is
B<not> running as a server process.

The first output parameter contains the full program name of the NexTrieve
executable "ntvsearch".  It contains the empty string if the "ntvsearch"
executable could not be found or is not executable by the effective user.
Can be used as a flag.  Is the only parameter returned in a scalar context.

If this method is called in a list context, an attempt is made to execute
the NexTrieve program "ntvsearch" to obtain additional information.  Then
the following output parameters are returned.

The second output parameter returns the expiration date of the license that
NexTrieve is using by default.  If available, then the date is returned as a
datestamp (YYYYMMDD).

The third output parameter returns the version of the NexTrieve software that
is being used.  It is a string in the form "M.m.rr", whereby "M" is the major
release number, "m" is the minor release number and "rr" is the build number.

The fourth output parameter returns the version of the internal database that
will be created by the version of the NexTrieve software that is being used.
It is a string in the form "M.m.rr", whereby "M" is the major release number,
"m" is the minor release number and "rr" is the build number.

=head1 OBJECT METHODS

These methods are available to the NexTrieve::Search object.

=head2 Hitlist

 $hitlist = $search->Hitlist( $xml | $query );
 $search->Hitlist( $xml | $query, filename );

The "Hitlist" method returns a NexTrieve::Hitlist object for a query or stores
the hitlist XML in the file specified.

The first input parameter specifies the query XML that should be sent to the
search service.  It can either be the "real" query XML that you created
yourself, or a NexTrieve::Query object.

The second input parameter is especially important if the "Hitlist" method
is called in a void context: it specifies the filename in which the hitlist
XML should be directly stored.

If the "Hitlist" method is called in a void context, the actual parsing of
the hitlist XML is skipped, making for a very much faster method.  This way
of calling the "Hitlist" method is especially handy when processing hitlist
XML using other means, e.g. the "xsltproc" program of the "libxml2" package
(as available from http://gnome.org ).

=head2 Resource

 $resource = $search->Resource;
 $search->Resource( $resource | file | xml | {method => value} );

The "Resource" method is primarily intended to allow you to obtain the
NexTrieve::Resource object that is (indirectly) created when the
NexTrieve::Search object is created.  If necessary, it can also be used
to create a new NexTrieve::Resource object associated with the
NexTrieve::Search object.

=head1 OTHER METHODS

The following methods address other properties of the NexTrieve::Search
object.

=head2 indexdir

 $search->indexdir( $indexdir );
 $indexdir = $search->indexdir;

The "indexdir" method specifies an indexdirectory B<other> than the
indexdirectory that is specified in the L<Resource> object.  By default, the
indexdirectory information from the L<Resource> object is used.

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
