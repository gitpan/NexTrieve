use Test;
BEGIN { plan tests => 12 }
END {
  ok(0) unless $loaded;
  unlink( @filename ) if @filename;
}

use NexTrieve qw(HTML);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => 1} );
my $version = $ntv->version;

# 02 Create empty HTML object
my $html = $ntv->HTML;
ok($html);

# 03 Create a simple document from an HTML stream
$document = $html->Document( <<EOD );
<html>
<head>
<title>This is the title</title>
</head>
<body>
This is the body
</body>
</html>
EOD
ok($document->xml,<<EOD );
<document>
<attributes>
<title>This is the title</title>
</attributes>
<text>
<title>This is the title</title>
This is the body
</text>
</document>
EOD

# 04 Create an external file that is slightly more complicated
my $filename = "$0.1.html";
my $handle = $html->openfile( $filename,'>' );
print $handle <<EOD;
<html>
<head>
<title>This is the title of 1</title>
<meta http-equiv="Content-type" content="text/html; charset=ISO-8859-1">
<meta name="description" content="Description of 1">
<meta name="keywords" content="Keywords of 1">
</head>
<body>
élève
This is the body of 1
</body>
</html>
EOD
close( $handle );
ok(-e $filename);
push( @filename,$filename ); #schedule for deletion

# 05 Check if the HTML can be read and produces correct XML
$document = $html->Document( $filename );
ok($document->xml,<<EOD);
<document>
<attributes>
<filename>$filename</filename>
<title>This is the title of 1</title>
</attributes>
<text>
<title>This is the title of 1</title>
<description>Description of 1</description>
<keywords>Keywords of 1</keywords>
élève
This is the body of 1
</text>
</document>
EOD

# 06 Check if the encoding of the document is correct
ok($document->encoding,'iso-8859-1');

# 07 Create an external file that is pretty bad HTML-wise
$filename = "$0.2.html";
$handle = $html->openfile( $filename,'>' );
print $handle <<EOD;
<!-- HTML comment -->
<script>this is a script that should not appear</script>
<title>This is the title of 2</title>
<meta http-equiv="Content-type" content="text/html; charset=UTF-8">
<meta name="description" content="Description of 2">
<meta name="keywords" content="Keywords of 2">
Ã©lÃ¨ve
This is the body of 2
EOD
close( $handle );
ok(-e $filename);
push( @filename,$filename ); #schedule for deletion

# 08 Check if the HTML can be read and produces correct XML
$document = $html->Document( $filename );
ok($document->xml,<<EOD);
<document>
<attributes>
<filename>$filename</filename>
<title>This is the title of 2</title>
</attributes>
<text>
<title>This is the title of 2</title>
<description>Description of 2</description>
<keywords>Keywords of 2</keywords>
Ã©lÃ¨ve
This is the body of 2
</text>
</document>
EOD

# 09 Check if the encoding of the document is correct
ok($document->encoding,'utf-8');

# 10 Attempt to create a docseq object out of this
$ntv->encoding( 'ISO-8859-1' );
my $docseq = $html->Docseq( @filename );
$docseq->done;
ok($docseq->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<filename>t/12html.t.1.html</filename>
<title>This is the title of 1</title>
</attributes>
<text>
<title>This is the title of 1</title>
<description>Description of 1</description>
<keywords>Keywords of 1</keywords>
élève
This is the body of 1
</text>
</document>
<document>
<attributes>
<filename>t/12html.t.2.html</filename>
<title>This is the title of 2</title>
</attributes>
<text>
<title>This is the title of 2</title>
<description>Description of 2</description>
<keywords>Keywords of 2</keywords>
élève
This is the body of 2
</text>
</document>
</ntv:docseq>
EOD

# 11 See if we can use the html2ntvml script
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
$handle = $html->openfile(
 "${basedir}../scripts/html2ntvml -e iso-8859-1 -f @filename |" );
ok($handle);

# 12 See if it creates the right docseq data
ok(join('',<$handle>),<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<filename>t/12html.t.1.html</filename>
<title>This is the title of 1</title>
</attributes>
<text>
<title>This is the title of 1</title>
<description>Description of 1</description>
<keywords>Keywords of 1</keywords>
élève
This is the body of 1
</text>
</document>
<document>
<attributes>
<filename>t/12html.t.2.html</filename>
<title>This is the title of 2</title>
</attributes>
<text>
<title>This is the title of 2</title>
<description>Description of 2</description>
<keywords>Keywords of 2</keywords>
élève
This is the body of 2
</text>
</document>
</ntv:docseq>
EOD
