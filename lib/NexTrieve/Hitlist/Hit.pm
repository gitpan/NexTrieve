package NexTrieve::Hitlist::Hit;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Hitlist::Hit::ISA = qw(NexTrieve); # nothing from NexTrieve::Hitlist
$NexTrieve::Hitlist::Hit::VERSION = '0.36';

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
directly, but through the Hit(s) method of the NexTrieve::Hitlist object.

Please note that the NexTrieve::Hitlist::Hit object is actually part of the
NexTrieve::Hitlist object and can therefore only be created through any module
that creates a NexTrieve::Hitlist object (such as the NexTrieve::Search module).

=head1 METHODS

The following methods are available to the NexTrieve::Hitlist::Hit object.

=head2 attributes

 @multi = $hit->attributes( 'multivaluedattributename' );

 $single = $hit->attributes( 'singlevaluedattributename' );
 ($one,$two,$three) = $hit->attributes( qw(attr1 attr2 attr3) );

 $hit->attributes( qw(attr1 attr2) ); # set @attr1, $attr1, @attr2 $attr2

The "attributes" method is a versatile method that returns the attribute
information of one or more attributes.

If an attribute is multi-valued (i.e. it has a multiplicity of "*" in the
NexTrieve resource file), then all the values of one such attribute can be
returned at a time.  In that case, the one and only input parameter is the
name of the attribute.

If the attributes in question, are single-valued (i.e. have a multiplicity of
"1" in the NexTrieve Resource file), then there are basically two modes of
operation.  In the first of those modes, you simply specify the name(s) of the
attribute(s) of which you want to obtain the values.  They are then returned
in the same order as with which the names are specified.

In the other of these modes, the "attributes" method is called in void
context.  It then sets the global variables and lists with the same name
as the name of the attribute in the namespace of the calling subroutine.  This
can be particularly handy in templating situations, where you want to quickly
access the result of a search query without being particularly interested in
the efficiency of execution.

=head2 docid

 $docid = $hit->docid;

The "docid" method returns the docid number of the document for which the
hit is returned in the hitlist.  It is an arbitrary number uniquely identifying
the document in the NexTrieve index.

=head2 ordinal

 $ordinal = $hit->ordinal;

The "ordinal" method returns the ordinal number of the hit in the conceptual
hitlist that was returned.  Its value is between the values returned by the
"firsthit" and "lasthit" methods of the NexTrieve::Hitlist object inclusive.

=head2 preview

 $preview = $hit->preview;

The "preview" method returns the preview that is associated with this
particular hit.  It is an XML string that may contain <B>...</B> containers
for highlighted words.

=head2 score

 $score = $hit->score;

The "score" method returns the score that is associated with this particular
hit.  It is a numeric value that has no meaning by itself but only in relation
to other values in the hitlist.  The value of the score determines the order
of the hits in the hitlist.

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
