package NexTrieve::Collection::Index;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Collection::Index::ISA = qw(NexTrieve);
$NexTrieve::Collection::Index::VERSION = '0.03';

# Use all the other NexTrieve modules that we need always

use NexTrieve::Daemon ();
use NexTrieve::Resource ();
use NexTrieve::Search ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods return objects

#------------------------------------------------------------------------

#  IN: 1..N any extra parameters valid for the NexTrieve::Resource object
# OUT: 1 instantiated NexTrieve::Resource object

sub Resource {

# Obtain the object
# Obtain the field name
# Return the object if we already have one and no new parameters

  my $self = shift;
  my $field = ref($self).'::Resource';
  return $self->{$field} if exists( $self->{$field} ) and !@_;

# Create local copy of the NexTrieve object
# Obtain the filename of the resource file
# Return and save created Resource object if file already exists
# Return and save created Resource object with newly created file

  my $ntv = $self->NexTrieve;
  my $filename = $self->path.'/'.$self->name.'.res';
  return $self->{$field} = $ntv->Resource( $filename ) if -e $filename;
  return $self->{$field} = $ntv->Resource->write_file( $filename );
} #Resource

#------------------------------------------------------------------------

#  IN: 1 server:port specification
# OUT: 1 instantiated NexTrieve::Daemon object

sub Daemon { shift->_object( 'Daemon',@_ )} #Daemon

#------------------------------------------------------------------------

# OUT: 1 instantiated NexTrieve::Search object

sub Search { shift->_object( 'Search',@_ ) } #Search

#------------------------------------------------------------------------

# The following methods are general stuff

#------------------------------------------------------------------------

# OUT: 1 name of collection

sub name { shift->_class_variable( 'name' ) } #name

#------------------------------------------------------------------------

# OUT: 1 path of collection

sub path { shift->_class_variable( 'path' ) } #path

#------------------------------------------------------------------------

# Following subroutines are for internal usage

#------------------------------------------------------------------------

#  IN: 1 name of object
#      2..N extra parameters
# OUT: 1 instantiated NexTrieve::(object) object

sub _object {

# Obtain the object
# Obtain the object name
# Obtain the field name
# Return the object if we already have one and no new parameters

  my $self = shift;
  my $object = shift;
  my $field = ref($self).'::'.$object;
  return $self->{$field} if exists( $self->{$field} ) and !@_;

# Allow for variable references
# Return the saved result of the object creation

  no strict 'refs';
  return $self->{$field} = $self->NexTrieve->$object( $self->Resource,@_ );
} #_object

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Collection::Index - handle a NexTrieve Collection Index

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $collection = $ntv->Collection( path );
 $index = $ntv->Index( name );

=head1 DESCRIPTION

The Collection::Index object of the Perl support for NexTrieve.  Do not create
directly, but through the Index method of the NexTrieve::Collection object.

=head1 OBJECT METHODS

These methods return objects.

=head2 Daemon

 $daemon = $collection->Daemon( server:port | port );

=head2 Resource

 $resource = $collection->Resource;

=head2 Search

 $search = $collection->Search;

=head1 OTHER METHODS

These are the other methods.

=head2 name

 $name = $collection->name;

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
