package NexTrieve::Hitlist::Hit;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Hitlist::Hit::ISA = qw(NexTrieve); # nothing from NexTrieve::Hitlist
$NexTrieve::Hitlist::Hit::VERSION = '0.01';

# Return true value for use

1;

#------------------------------------------------------------------------

#  IN: 1..N names of single valued attributes (default: all in void context)
# OUT: 1..N values (firsts if >1 attribute, else all of single attribute)
# sets variables in caller's namespace if called in void contect

sub attributes {

# Obtain the object
# Obtain the reference to the hash

  my $self = shift;
  my $hash = $self->[2];

# If we're expected to return a list
#  Return multivalued single attribute data if only one name specified
#  Return all first values of the attribute names specified

  if (wantarray) {
    return map {$_->[1]} @{$hash->{scalar(shift)}} if @_ == 1;
    return map {
                exists( $hash->{$_} ) ? $hash->{$_}->[0]->[1] || 1 : undef
               } @_;
  }

# If we're expecting a scalar value
#  Add error if there is more than one name specified
#  Fetch all values of the first attribute and return them

  if (defined(wantarray)) {
    my $name = shift;
    $self->_add_error( "Can only return a single value, multiple attribute names specified, returning only '$name'" ) if @_;
    return map {$_->[1]} @{$hash->{$name}};
  }

# Allow variable references
# Obtain the namespace to be used
# For all of the attributes specified
#  Obtain all of the values and put as list in namespace
#  If an attribute exists but has no value, it is a flag and it should be set
#  Make sure the first value of the list is also a scalar in the namespace

  no strict 'refs';
  my $namespace = caller().'::';
  foreach my $name (@_) {
    my $fullname = $namespace.$name;
    @{$fullname} = map {$_->[1] || 1} @{$hash->{$name}};
    ${$fullname} = (@{$fullname})[0];
  }
} #attributes

#------------------------------------------------------------------------

# OUT: 1 docid of hit

sub docid { shift->[0]->{'docid'} } #docid

#------------------------------------------------------------------------

# OUT: 1 ordinal number of hit

sub ordinal { shift->[0]->{'ordinal'} } #ordinal

#------------------------------------------------------------------------

# OUT: 1 preview of hit

sub preview { shift->[1] } #preview

#------------------------------------------------------------------------

# OUT: 1 score of hit

sub score { shift->[0]->{'score'} } #score

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Hitlist::Hit - handle the Hit specifications of NexTrieve

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = NexTrieve->new( | {method => value} );
 $search = $ntv->Search( file | $resource | server:port | port );
 $query = $ntv->Query( | file | xml | {method => value} );
 $hitlist = $search->Hitlist( $query | xml | {method => value} );

 # loop through all hits
 foreach $hit ($hitlist->Hits) { }

 # get a specific hit
 $hit = $hitlist->Hit( $ordinal );

=head1 DESCRIPTION

The Hit object of the Perl support for NexTrieve.  Do not create
directly, but through the Hit method of the NexTrieve::Hitlist object.

=head1 METHODS

The following methods are available to the NexTrieve::Hitlist::Hit object.

=head2 attributes

 @multi = $hit->attributes( 'multivaluedattributename' );

 $single = $hit->attributes( 'singlevaluedattributename' );

 ($one,$two,$three) = $hit->attributes( qw(attr1 attr2 attr3) );

 $hit->attributes( qw(attr1 attr2) ); # set @attr1, $attr1, @attr2 $attr2

=head2 docid

 $docid = $hit->docid;

=head2 ordinal

 $ordinal = $hit->ordinal;

=head2 preview

 $preview = $hit->preview;

=head2 score

 $score = $hit->score;

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
