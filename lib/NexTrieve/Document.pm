package NexTrieve::Document;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Document::ISA = qw(NexTrieve);
$NexTrieve::Document::VERSION = '0.02';

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods add data to the object

#------------------------------------------------------------------------

#  IN: 1 name of attribute
#      2..N value of attributes

sub attribute { 

# Obtain the object
# Make sure all XML is removed
# Save this attribute

  my $self = shift;
  $self->_kill_xml;
  push( @{$self->{ref($self).'::attributes'}},[@_] );
} #attribute

#------------------------------------------------------------------------

#  IN: 1..N listref to all names and value(s)

sub attributes {

# Obtain the object
# Make sure all XML is removed
# Set this as all attributes

  my $self = shift;
  $self->_kill_xml;
  @{$self->{ref($self).'::attributes'}} = @_;
} #attributes

#------------------------------------------------------------------------

#  IN: 1 name of texttype (optional if only 1 text value)
#      2..N (reference to) text to be added

sub text {

# Obtain the object
# Make sure all XML is removed
# Add this text

  my $self = shift;
  $self->_kill_xml;
  push( @{$self->{ref($self).'::texts'}},[@_] );
} #text

#------------------------------------------------------------------------

#  IN: 1..N listref to all texttype names and values

sub texts {

# Obtain the object
# Make sure all XML is removed
# Set this as _all_ text

  my $self = shift;
  $self->_kill_xml;
  @{$self->{ref($self).'::texts'}} = @_;
} #texts

#------------------------------------------------------------------------

# Following subroutines are for internal use only

#------------------------------------------------------------------------

sub _delete_dom {

# Obtain the object
# Obtain the class of the object

  my $self = shift;
  my $class = ref($self);

# For all of the fields that are used in this dom
#  Remove it

  foreach ('',qw(
   ::attributes
   ::encoding
   ::texts
   ::version
    )) {
    delete( $self->{$class.$_} );
  }
} #_delete_dom

#------------------------------------------------------------------------

sub _create_dom {} #_create_dom

#------------------------------------------------------------------------

# OUT: 1 <document> XML

sub _create_xml {

# Obtain the object
# Obtain the class definition to be used
# Return now if we have XML already

  my $self = shift;
  my $class = ref($self);
  return $self->{$class.'::xml'} if $self->{$class.'::xml'};

# Initialize the XML

  my $xml = "<document>\n";

# Set the field name to use
# If there are attributes specified
#  Start the attributes container
#  For all of the attributes specified
#   Obtain the name
#   For all of the values
#    Add container
#  Close the attributes container

  my $field = $class.'::attributes';
  if ($self->{$field} and @{$self->{$field}}) {
    $xml .= "<attributes>\n";
    foreach my $list (@{$self->{$field}}) {
      my $name = shift(@{$list});
      foreach my $value (@{$list}) {
        $xml .= "<$name>$value</$name>\n";
      }
    }
    $xml .= "</attributes>\n";
  }

# Set the field name to use
# If there are texts specified
#  Start the text container
#  For all of the texts specified
#   If there is a name
#    For all of the values
#     Add container
#   Else
#    For all of the values
#     Just add
#  Close the text container

  $field = $class.'::texts';
  if ($self->{$field} and @{$self->{$field}}) {
    $xml .= "<text>\n";
    foreach my $list (@{$self->{$field}}) {
      if (my $name = @{$list} > 1 ? shift(@{$list}) : '') {
        foreach my $value (@{$list}) {
          $xml .= ref($value) ?
           "<$name>$$value</$name>\n" : "<$name>$value</$name>\n";
        }
      } else {
        foreach my $value (@{$list}) {
          $xml .= ref($value) ? "$$value\n" : "$value\n";
        }
      }
    }
    $xml .= "</text>\n";
  }

# Close the document container
# Return the finished XML

  $xml .= "</document>";
  return $self->{$class.'::xml'} = $xml;
} #_create_xml

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Document - create XML for indexing a single document

=head1 SYNOPSIS

 use NexTrieve;
 $ntv = new NexTrieve( | {method => value} );
 $index = $ntv->Index( | filename | xml | $resource );

 $docseq = $index->Docseq( | encoding );
 $document = $ntv->Document( | {method->value} );
 $docseq->add( $document );

=head1 DESCRIPTION

The Document object of the Perl support for NexTrieve.  Do not create
directly, but through the Document method of the NexTrieve object.

 $document = $ntv->Document( | {method => value} );

=head1 METHODS

The following methods apply to the adding of attributes and text.

=head2 attribute

 $document->attribute( name,@value );

=head2 attributes

 $document->attributes( [name1,@value1], [name2,@value2] ... [nameN,@valueN] )

=head2 text

 $document->text( | name,@text );

=head2 texts

 $document->texts( [name1,@value1], [name2,@value2] ... [nameN,@valueN] );

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
