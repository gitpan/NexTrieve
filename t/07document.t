use Test;
BEGIN { plan tests => 6 }
END { ok(0) unless $loaded }

use NexTrieve qw(Document);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => 1} );
my $version = $ntv->version;

# 02 Create empty document file, check version
my $document = $ntv->Document;
ok( $document->version,undef );

# 03 Check whether empty document file comes out ok
ok( $document->xml,qq(<document>\n</document>) );

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
ok($document->xml."\n",$xml);

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
ok($document->xml."\n",$xml);

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
ok($document->xml."\n",$xml);
