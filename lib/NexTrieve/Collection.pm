package NexTrieve::Collection;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Collection::ISA = qw(NexTrieve);
$NexTrieve::Collection::VERSION = '0.34';

# Use all the other NexTrieve modules that we need always

use NexTrieve::Collection::Index ();

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

#  IN: 1 name of index within collection
#      2 flag: whether to create
# OUT: 1 instantiated NexTrieve::Collection::Index object

sub Index {

# Obtain the object
# Obtain the base path of the Collection
# Return now with error if the directory doesn't exist

  my $self = shift;
  my $path = $self->path;
  return $self->_add_error( "'$path' is not a valid Collection" )
   unless -d $path;

# Obtain the class of the index object
# Create an index object
# Make sure it has a copy of the NexTrieve object
# Inherit anything that we need

  my $class = ref($self).'::Index';
  my $index = bless {},$class;
  $index->{'Nextrieve'} = $self->NexTrieve;
  $index->_inherit;

# Obtain the name
# Make sure it is free of strange stuff
# Save the name of the index in the object

  my $name = shift;
  $name =~ s#[\W]##sg;
  $index->{$class.'::name'} = $name;

# Add to the already existing path
# Save that as the path in the object

  $path .= "/$name";
  $index->{$class.'::path'} = $path;

# Obtain the creation flag
# Set flag to indicate it already exists

  my $create = shift || 0;
  my $exists = ($path ne '' and -d $path);

# If the path already exists
#  Return with error if it should be created
# Elsif a path was specified
#  If we're supposed to create the collection
#   Attempt to create the directory, return with error if failed

  if ($exists) {
    return $index->_add_error(
     "'$path' already exists as a NexTrieve Collection Index" ) if $create;
  } elsif ($path) {
    if ($create) {
      mkdir( $path,0700 ) or
       return $index->_add_error( "Cannot create '$path': $!" );

#  Else (collection is supposed to exist, but doesn't)
#   Return with error
# Else (no path specified)
#   Return with error

    } else {
      return $index->_add_error( "'$path' is not a NexTrieve Collection Index" );
    }
  } else {
    return $index->_add_error(
     "Must specify the path of the NexTrieve Collection Index" );
  }

# Return the object

  return $index;
} #Index

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

=head2 Index

 $index = $collection->Index( mnemonic );

=head1 OTHER METHODS

These are the other methods.

=head2 path

 $path = $collection->path;

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
