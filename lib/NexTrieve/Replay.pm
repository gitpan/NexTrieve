package NexTrieve::Replay;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Replay::ISA = qw(NexTrieve);
$NexTrieve::Replay::VERSION = '0.01';

# Use all of the NexTrieve submodules that we need for sure

use NexTrieve::Querylog ();
use NexTrieve::Search ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods change the object

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
    next if exists $self->{$self.'::'.$_};
    $self->_add_error( "Must have a valid $_ object" );
    return;
  }

# Obtain the next query
# Return now if there is no query
# Return whatever is the result of the query

  my $query = $self->{$class.'::Querylog'}->Query;
  return unless $query;
  return $self->{$class.'::Search'}->Hitlist( $query );
} #Hitlist

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Replay - replay Querylog objects against Search objects

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $replay = $ntv->Replay( {method => value} );

=head1 DESCRIPTION

The Replay object of the Perl support for NexTrieve.  Do not create
directly, but through the Replay method of the NexTrieve object.

=head1 METHODS

These methods are available to the NexTrieve::Replay object.

=head2 Hitlist

 $hitlist = $replay->Hitlist;

=head2 Querylog

 $replay->Querylog( $ntv->Querylog( filename ) );
 $querylog = $replay->Querylog;

=head2 Search

 $replay->Search( $ntv->Search( $resource | server:port | port ) );
 $search = $replay->Search;

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
