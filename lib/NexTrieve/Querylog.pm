package NexTrieve::Querylog;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Querylog::ISA = qw(NexTrieve);
$NexTrieve::Querylog::VERSION = '0.01';

# Use all of the NexTrieve submodules that we need for sure

use NexTrieve::Query ();

# Return true value for use

1;

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 filename
#      3 reference to hash with method/value pairs

sub _new {

# Obtain the class of the object
# Attempt to create the base object
# Set the filename
# Return the object

  my $class = shift;
  my $self = $class->SUPER::_new( shift );
  $self->filename( shift ) if @_;
  return $self;
} #_new

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 new filename specification
# OUT: 1 current/old filename specification

sub filename {

# Obtain the handle

  my $self = shift;

# If there is a new filename
#  Obtain the class
#  Delete the handle (if any)

  if (@_) {
    my $class = ref($self);
    delete( $self->{$class.'::handle'} );
  }

# Handle as a normal setting/returning

  return $self->_class_variable( 'filename',@_ );
} #filename

#------------------------------------------------------------------------

# OUT: 1 next NexTrieve Query object (undef if end reached)
#      2 localtime string when query was done

sub Query {

# Obtain the object
# Obtain the class

  my $self = shift;
  my $class = ref($self);

# Initialize the handle
# If we don't have a handle yet
#  If there is a filename
#   Attempt to open the file, saving handle on the fly
#   Return now if there is no handle
#  Else
#   Add error to object and return

  my $handle;
  unless ($handle = $self->_handle || '') {
    if (my $filename = $self->filename) {
      $self->_handle( $handle = $self->openfile( $filename ) );
      return unless $handle;
    } else {
      $self->_add_error( "Don't know which querylog file to open" );
      return;
    }
  }

# Until we have a valid object
#  Obtain the time value
#  Return now if failed

  while (1) {
    chomp( my $localtime = <$handle> || '' );
    return unless $localtime;

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

#  Create the query object
#  Return the result of the creation of the query from the XML

    my $query = $self->NexTrieve->Query( $xml );
    return wantarray ? ($query,$localtime) : $query;
  }
} #Query

#------------------------------------------------------------------------

# The following subroutines are for internal use only

#------------------------------------------------------------------------

#  IN: 1 new handle specification
# OUT: 1 current/old handle specification

sub _handle { shift->_class_variable( 'handle',@_ ) } #_handle

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Querylog - handle NexTrieve as a querylog

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $querylog = $ntv->Querylog( file | $resource );

=head1 DESCRIPTION

The Querylog object of the Perl support for NexTrieve.  Do not create
directly, but through the Querylog method of the NexTrieve object.

=head1 METHODS

These methods are available to the NexTrieve::Querylog object.

=head2 Query

 ($query,$localtime) = $querylog->Query;

=head2 filename

 $querylog->filename( filename );
 $filename = $querylog->filename;

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
