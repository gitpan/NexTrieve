package NexTrieve::Replay;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Replay::ISA = qw(NexTrieve);
$NexTrieve::Replay::VERSION = '0.35';

# Use all of the NexTrieve submodules that we need for sure

use NexTrieve::Querylog ();
use NexTrieve::Search ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

# OUT: 1 Query object associated with last Hitlist obtained

sub Query { $_[0]->{ref(shift).'::Query'} } #Query

#------------------------------------------------------------------------

#  IN: 1 new Querylog object specification
# OUT: 1 current/old Querylog object specification

sub Querylog { shift->_class_variable( 'Querylog',@_ ) } #Querylog

#------------------------------------------------------------------------

#  IN: 1 new Search object specification
# OUT: 1 current/old Search object specification

sub Search { shift->_class_variable( 'Search',@_ ) } #Search

#------------------------------------------------------------------------

# OUT: 1 next NexTrieve Hitlist object (undef if end reached)

sub Hitlist {

# Obtain the object
# Obtain the class

  my $self = shift;
  my $class = ref($self);

# Check for all the objects that we need
#  Reloop if there is an object
#  Add error and return (no object found)

  foreach (qw(Querylog Search)) {
    next if exists $self->{$class.'::'.$_};
    $self->_add_error( "Must have a valid $_ object" );
    return;
  }

# Obtain the next query
# Return now if there is no query
# Return whatever is the result of the query

  my $query = $self->{$class.'::Querylog'}->Query;
  return unless $query;
  return $self->{$class.'::Search'}->Hitlist(
   $self->{$class.'::Query'} = $query );
} #Hitlist

#------------------------------------------------------------------------

# The following objects apply to the object

#------------------------------------------------------------------------

# OUT: 1 flag whether at end of querylog

sub eof { shift->Querylog->eof } #eof;

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Replay - replay Querylog objects against Search objects

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $replay = $ntv->Replay( {method => value} );

 $replay = $ntv->Replay( {Search => $search, Querylog => $querylog} );
 while (!$replay->eof) {
   $hitlist = $replay->Hitlist;
 }

=head1 DESCRIPTION

The Replay object of the Perl support for NexTrieve.  Do not create
directly, but through the Replay method of the NexTrieve object.

The NexTrieve::Replay module allows you to re-perform queries that were logged
in a query log file, to be searched again against the same or another
search engine service.  It is mainly intended for debugging and research
purposes.

=head1 OBJECT METHODS

The following methods return objects.

=head2 Hitlist

 $hitlist = $replay->Hitlist;

The "Hitlist" method returns the next NexTrieve::Hitlist object that was the
result of the next L<Query> that was found in the L<Querylog> that was "played"
against the L<Search> object.

The undefined value is returned when there were no more queries available in
the query log file.  The L<eof> method can be called in advance to find out
whether there are any queries left in the query log file.

See the NexTrieve::Hitlist module for more information.

=head2 Query

 $query = $replay->Query;

The "Query" method returns the NexTrieve::Query object that was used to create
the last NexTrieve::L<Hitlist> object that was returned.

See the NexTrieve::Query module for more information.

=head2 Querylog

 $replay->Querylog( $ntv->Querylog( filename ) );
 $querylog = $replay->Querylog;

The "Querylog" method specifies the NexTrieve::Querylog object that should be
used to obtain queries from.

See the NexTrieve::Querylog module for more information.

=head2 Search

 $replay->Search( $ntv->Search( $resource | server:port | port ) );
 $search = $replay->Search;

The "Search" method specifies the NexTrieve::Search object that should be
used to send queries to and obtain hitlists from.

See the NexTrieve::Search module for more information.

=head1 OTHER METHODS

These methods show other properties of the NexTrieve::Replay module.

=head2 eof

 $isnowatend = $replay->eof;

The "eof" method returns whether there are no more queries found in the
L<Querylog> file.  If it returns true, then all subsequent calls to L<Hitlist>
will return the undefine value.

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
