use strict;
use warnings;
use Test;

use vars qw($loaded $xml);

BEGIN { plan tests => 8 }
END { ok(0) unless $loaded }

use NexTrieve qw(Document);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create empty document file, check version
my $document = $ntv->Document;
ok( $document->version,undef );

# 03 Check whether empty document file comes out ok
$document->xml unless ok( $document->xml,'' );

# Initalize the XML to check against
$xml = <<EOD;
<document>
<attributes>
<attr1>value1</attr1>
<attr2>value2</attr2>
<attr2>value2a</attr2>
</attributes>
<text>
<title>This is text in a title texttype</title>
This is a default text, which can be specified as a single string
<footer>This is a footer text</footer>
</text>
</document>
EOD

# 04 Add attributes and text to existing object
$document = $ntv->Document;
$document->attribute( qw(attr1 value1) );
$document->attribute( qw(attr2 value2 value2a) );
$document->text( 'title','This is text in a title texttype' );
$document->text(
 'This is a default text, which can be specified as a single string' );
$document->text( 'footer','This is a footer text' );
$document->xml unless ok($document->xml."\n",$xml);

# 05 Add all attributes and text to existing object
$document = $ntv->Document;
$document->attributes(
 [qw(attr1 value1)],
 [qw(attr2 value2 value2a)],
);
$document->texts(
 ['title','This is text in a title texttype'],
 ['This is a default text, which can be specified as a single string'],
 ['footer','This is a footer text'],
);
$document->xml unless ok($document->xml."\n",$xml);

# 06 Add attributes and text while creating object
$document = $ntv->Document( {
 attributes =>
  [
   [qw(attr1 value1)],
   [qw(attr2 value2 value2a)],
  ],
 texts =>
  [
   ['title','This is text in a title texttype'],
   ['This is a default text, which can be specified as a single string'],
   ['footer','This is a footer text'],
  ],
} );
$document->xml unless ok($document->xml."\n",$xml);

# 07 Check if incorrect XML causes error with xmllint and comes out empty
$document = $ntv->Document;
$document->RaiseError( 0 );
$document->xml( <<EOD );
<open>This is incorrect XML</close>
EOD
$document->xmllint( 1 );
my $skip = $document->xmllint ? '' : "xmllint not available";
skip($skip,$document->xml,''); 

# 08 Check if there are indeed errors
skip($skip,$document->Errors);
