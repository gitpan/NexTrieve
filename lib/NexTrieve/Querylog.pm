package NexTrieve::Querylog;

# Set modules to inherit from
# Set version information
# Make sure we do everything by the book from now on

@ISA = qw(NexTrieve);
$VERSION = '0.41';
use strict;

# Use all of the NexTrieve submodules that we need for sure

use NexTrieve::Query ();

# Satisfy -require-

1;

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 filename
#      3 reference to hash with method/value pairs

sub _new {

# Obtain the class of the object
# Attempt to create the base object
# Set the filename
# Set any other parameters
# Return the object

  my $class = shift;
  my $self = $class->SUPER::_new( shift );
  $self->filename( shift ) if @_;
  $self->Set( shift ) if @_;
  return $self;
} #_new

#------------------------------------------------------------------------

# The folloing methods return objects

#------------------------------------------------------------------------

# OUT: 1..N query objects for all queries in the log

sub Queries {

# Obtain the object
# Initialize the list of queries

  my $self = shift;
  my @query;

# Obtain local copy of the handle
# Find out where we're at
# While there are more queries to fetch
#  Save it in the list

  my $handle = $self->_handle;
  my $tell = tell( $handle );
  while (my $query = $self->Query) {
    push( @query,$query );
  }

# Seek back to the position where we were
# Return the final list of queries

  seek( $self->_handle,$tell,0 );
  return @query;
} #Queries

#------------------------------------------------------------------------

# OUT: 1 next NexTrieve Query object (undef if end reached)
#      2 localtime string when query was done

sub Query {

# Obtain the object
# Obtain the field name
# Return now if there are no more queries

  my $self = shift;
  my $field = ref($self).'::NEXT';
  return unless exists( $self->{$field} );

# Remember the current setting
# Process the next one
# Return what we had

  my $list = $self->{$field};
  $self->_next;
  return wantarray ? @{$list} : $list->[0];
} #Query

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

# OUT: 1 flag whether at end of query logfile

sub eof { !exists( $_[0]->{ref(shift).'::NEXT'} ) } #eof

#------------------------------------------------------------------------

#  IN: 1 new filename specification
# OUT: 1 current/old filename specification

sub filename {

# Obtain the object

  my $self = shift;

# If we have new parameters
#  Obtain the handle
#  Get first query if we have a handle

  if (@_) {
    $self->_handle( my $handle = $self->openfile( shift,'<' ) );
    $self->_next if $handle;
  }

# Handle as a normal setting/returning

  return $self->_class_variable( 'filename',@_ );
} #filename

#------------------------------------------------------------------------

# The following subroutines are for internal use only

#------------------------------------------------------------------------

#  IN: 1 new handle specification
# OUT: 1 current/old handle specification

sub _handle { shift->_class_variable( 'HANDLE',@_ ) } #_handle

#------------------------------------------------------------------------

sub _next {

# Obtain the object
# Set the field name to be used

  my $self = shift;
  my $field = ref($self).'::NEXT';

# Obtain the handle
# If we don't have a handle yet
#  Add error to object and return

  my $handle = $self->_handle;
  unless ($handle) {
    $self->_add_error( "Don't know which querylog file to open" );
    return;
  }

# Until we have a valid object
#  Obtain the time value
#  If failed
#   Remove the next object and return

  while (1) {
    chomp( my $localtime = <$handle> || '' );
    unless ($localtime) {
      delete( $self->{$field} );
      return;
    }

#  Initialize the XML
#  While there are lines to be read
#   Add the line to the XML
#   Quit now if we reached the end

    my $xml = '';
    while (<$handle>) {
      $xml .= $_;
      last if m#</ntv:query>#;
    }

#   Reloop if it is a "ping"

    next if $xml eq <<EOD; # same string as in NexTrieve::Daemon::ping
<ntv:query xmlns:ntv="http://www.nextrieve.com/1.0" type="exact" totalhits="1" longform="0" showattributes="0" showpreviews="1">ping</ntv:query>
EOD

#  Save the query object as the next object to be returned and return

    $self->{$field} = [$self->NexTrieve->Query( $xml ),$localtime];
    return;
  }
} #Query

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Querylog - handle NexTrieve as a querylog

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $querylog = $ntv->Querylog( file | $resource );

 while (!$querylog->eof) {
   $query = $querylog->Query;
 }

=head1 DESCRIPTION

The Querylog object of the Perl support for NexTrieve.  Do not create
directly, but through the Querylog method of the NexTrieve object.

When NexTrieve is run as a server process (see the NexTrieve::Daemon module),
a log of queries is kept.  This module operates on such a log file and returns
NexTrieve::Query objects from a such a log file.

=head1 OBJECT METHODS

These methods return one or more objects.

=head2 Queries

 @query = $querylog->Queries;

The "Queries" object returns a list of NexTrieve::Query objects of all queries
that were logged in the log file that was indicated upon creation of the
NexTrieve::Querylog object, or which has been specified by the L<filename>
method.

See the documentation of the NexTrieve::Query module for more information.

=head2 Query

 $query = $querylog->Query;
 ($query,$localtime) = $querylog->Query;

The "Query" object returns the next NexTrieve::Query object of the queries
that were logged in the log file that was indicated upon creation of the
NexTrieve::Querylog object, or which has been specified by the L<filename>
method.

If there are no more queries to be found in the query log file, then an
undefined value is returned.  It is also possible to call the L<eof> method
to find out whether there are any more queries available before calling the
"Query" method.

If called in a list context, the time (as a localtime() string) when the
query was originally done, is also returned as the second output parameter.

See the documentation of the NexTrieve::Query module for more information.

=head1 OTHER METHODS

These methods allow you to check or change other aspects of the
NexTrieve::Querylog object.

=head2 eof

 $atendoffile = $querylog->eof;

The "eof" method returns true if there are no more queries left in the
NexTrieve::Querylog object to be returned by the L<Query> method.

Please note that if the L<Queries> method was used, this method will B<always>
return true.

=head2 filename

 $querylog->filename( filename );
 $filename = $querylog->filename;

The "filename" method can be used to change to another query log file or to
specify the first query log file if none was specificied when the
NexTrieve::Querylog object was created.

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
