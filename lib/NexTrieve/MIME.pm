package NexTrieve::MIME;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::MIME::ISA = qw(NexTrieve);
$NexTrieve::MIME::VERSION = '0.29';

# Use other NexTrieve modules that we need always

use NexTrieve ();

# Create the list of displaycontainers for matching (no space around it)
# Create the list of containers of which the content will be removed

my $displaycontainers = NexTrieve->_default_displaycontainers;
my $removecontainers = NexTrieve->_default_removecontainers;

# Initialize the hash with routines for handling the text

my %mimeprocessor = (
 'text/html'    => \&_html,
 'text/plain'   => \&_plain,
 'text/x-diff'  => \&_plain,
);

# Return true value for use

1;

#------------------------------------------------------------------------

# OUT: 1 reference to %mimeprocessor

sub processor { \%mimeprocessor } #processor

#------------------------------------------------------------------------

# Routines that handle a specific (group of) mime-type(s)

#------------------------------------------------------------------------

#  IN: 1 object
#      2 HTML to process
#      3 encoding found for this HTML
#      4 document object
# OUT: 1 text to be added to the XML

sub _html {

# Obtain the parameters
# Obtain the length of the text
# Return now if nothing to do

  my ($self,$html,$encoding,$document) = @_;
  my $length = length($html);
  return '' unless $length;

# If we're supposed to do the binary file check
#  Calculate the number of ISO-8859-1 illegal characters
#  If we think they indicate a binary file
#   Put out an error
#   Return with nothing

  if ($self->binarycheck) {
    my $count = $html =~ tr#\x00-\x08\x0b-\x0c\x0e-\x1a\x1c-\x1f##;
    if ($count > 100 or $count/$length > .01) {
      $self->_add_error( "HTML part is probably binary" );
      return '';
    }
  }

# If there is a character encoding in there
#  Make _that_ our characterencoding from now

  if ($html =~ s#<meta\s+http-equiv="content-type"\s+content="text/html;\s*charset=\s*(.*?)">##si) {
    $encoding = $self->_normalize_encoding( $1 );
  }

# If there is a character encoding in this part
#  If there is a document encoding already
#   Adjust the character encoding if they are different
#  Else (no encoding in document yet)
#   Set the document encoding to this

  if ($encoding) {
    if (my $documentencoding = $document->encoding) {
      $html = $document->recode($documentencoding,$html,$encoding)
       if $encoding ne $documentencoding;
    } else {
      $document->encoding( $encoding );
    }
  }

# Get rid of anything that looks like a comment
# Make sure all of the tags are in lowercase (simplifies further matching)

  $html =~ s#<!--.*?-->##sg;
  $html =~ s#(</?\w+)#\L$1\E#sgi;

# Obtain the name of the containers to be removed with their content
# Get rid of anything that should be removed

  my $containers = $self->removecontainers || $removecontainers;
  $html =~ s#<($containers)\b[^>]*>.*?</\1[^>]*>##sg;

# If there is html to process
#  Obtain the display containers
#  Throw away any displayable containers inside the html completely
#  Replace all other containers by a space
#  Make sure the text is valid XML
#  Add the text to the MIME object (will be added later if no text available)

  if ($html) {
    $containers = $self->displaycontainers || $displaycontainers;
    $html =~ s#<($containers)\b[^>]*>(.*?)</\1[^>]*>#$2#sg;
    $html =~ s#<[^<>]*># #sg;
    $self->normalize( $html );
    $self->{ref($self).'::html'} .= $html;
  }

# Return nothing (HTML is only used when there is no text available)

  return '';
} #_html

#------------------------------------------------------------------------

#  IN: 1 object
#      2 text to process
#      3 encoding found for this part
#      4 document object
# OUT: 1 text to be added to the XML

sub _plain {

# Obtain the parameters
# Obtain the length of the text
# Return now if nothing to do

  my ($self,$text,$encoding,$document) = @_;
  my $length = length($text);
  return '' unless $length;

# If we're supposed to do the binary file check
#  Calculate the number of ISO-8859-1 illegal characters
#  If we think they indicate a binary file
#   Put out an error
#   Return with nothing

  if ($self->binarycheck) {
    my $count = $text =~ tr#\x00-\x08\x0b-\x0c\x0e-\x1a\x1c-\x1f##;
    if ($count > 100 or $count/$length > .01) {
      $self->_add_error( "Text part is probably binary" );
      return '';
    }
  }

# If there is a character encoding in this part
#  If there is a document encoding already
#   Adjust the character encoding if they are different
#  Else (no document encoding yet)
#   Set the document encoding to this

  if ($encoding) {
    if (my $documentencoding = $document->encoding) {
      $text = $document->recode($documentencoding,$text,$encoding)
       if $encoding ne $documentencoding;
    } else {
      $document->encoding( $encoding );
    }
  }

# Make sure the text is valid XML
# Clean out text completely if only whitespace
# Return the adapted text

  $self->ampersandize( $text );
  $text =~ s#^\s+$##s;
  return $text;
} #_plain

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::MIME - MIME-type conversions for documents

=head1 SYNOPSIS

 # do not use directly, just a repository of conversion routines

=head1 DESCRIPTION

The NexTrieve::MIME package contains the standard set of subroutines for
conversion from a MIME-type to XML-ready text.

The following subroutines are currently available:

 _plain      convert from plain text
 _html       convert from HTML

The main users of these subroutines are the NexTrieve::RFC822 and
NexTrieve::Message modules.

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
