package NexTrieve::Collection;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Collection::ISA = qw(NexTrieve);
$NexTrieve::Collection::VERSION = '0.01';

# Use all the other NexTrieve modules that we need always

use NexTrieve::Resource ();

# Return true value for use

1;

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 path
#      3 flag: whether to create
# OUT: 1 instantiated NexTrieve::Collection object

sub _new {

# Obtain the class of the object
# Attempt to create the base object

  my $class = shift;
  my $self = $class->SUPER::_new( shift );

# Obtain the path
# Obtain the creation flag
# Obtain the exists flag

  my $path = shift || '';
  my $create = shift || 0;
  my $exists = ($path ne '' and -d $path);

# If the path already exists
#  Return with error if it should be created
# Elsif a path was specified
#  If we're supposed to create the collection
#   Attempt to create the directory, return with error if failed

  if ($exists) {
    return $self->_add_error( "'$path' already exists as a NexTrieve Collection" ) if $create;
  } elsif ($path) {
    if ($create) {
      mkdir( $path,0700 ) or
       return $self->_add_error( "Cannot create '$path': $!" );

#  Else (collection is supposed to exist, but doesn't)
#   Return with error
# Else (no path specified)
#   Return with error

    } else {
      return $self->_add_error( "'$path' is not a NexTrieve Collection" );
    }
  } else {
    return $self->_add_error( "Must specify the path of the NexTrieve Collection" );
  }

# Save the path in the object
# Return the object

  $self->{$class.'::path'} = $path;
  return $self;
} #_new

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1 mnemonic of part within collection
#      2..N any extra parameters valid for the NexTrieve::Resource object
# OUT: 1 instantiated NexTrieve::Resource object

sub Resource {

# Obtain the object
# Obtain the base path of the Collection
# Return now with error if the directory doesn't exist

  my $self = shift;
  my $path = $self->path;
  return $self->_add_error( "'$path' is not a valid Collection" )
   unless -d $path;

# Obtain the mnemonic
# Add to the already existing path
# Create the filename

  my $mnemonic = shift;
  $path .= "/$mnemonic";
  my $filename = "$path/$mnemonic.res";

# Create local copy of the NexTrieve object
# Return the result of the Resource creation if existing file

  my $ntv = $self->NexTrieve;
  return $ntv->Resource( $filename ) if -e $filename;

# If there is no directory for this mnemonic yet
#  Attempt to create directory or return error

  unless (-d $path) {
    mkdir( $path,0700 ) or
     return $self->_add_error( "Cannot create '$path': $!" );
  }

# Create a new, empty resource file and return object of it

  return $ntv->Resource->write_file( $filename );
} #Resource

#------------------------------------------------------------------------

#  IN: 1 mnemonic of part within collection
#      2 logical index (optional)
# OUT: 1 instantiated NexTrieve::Search object

sub Search {

# Obtain the object
# Return the result of the Search creation

  my $self = shift;
  return $self->NexTrieve->Search( $self->Resource( shift ),@_ );
} #Search

#------------------------------------------------------------------------

# The following methods are general stuff

#------------------------------------------------------------------------

# OUT: 1 path of collection

sub path { shift->_class_variable( 'path' ) } #path

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Collection - handle a NexTrieve Collection

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $collection = $ntv->Collection( path );

=head1 DESCRIPTION

The Collection object of the Perl support for NexTrieve.  Do not create
directly, but through the Collection method of the NexTrieve object.

=head1 OBJECT METHODS

These methods return objects.

=head2 Resource

 $resource = $collection->Resource( mnemonic );

=head2 Resource

 $search = $collection->Search( mnemonic );

=head1 OTHER METHODS

These are the other methods.

=head2 path

 $path = $collection->path;

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
