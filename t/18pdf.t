use Test;
BEGIN { $tests = 6; plan tests => $tests }
END {
  ok(0) unless $loaded;
}

use NexTrieve qw(PDF Resource);
$loaded = 1;

my $ntv = NexTrieve->new( {RaiseError => 'confess'} );
my $version = $ntv->version;
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';

unless (NexTrieve::PDF->executable) {
  print "ok $_ # skip 'pdftotext' not executable or not found\n" foreach 1..$tests;
  exit;
}
ok( 1 );

# 02 Create empty HTML object
my $pdf = $ntv->PDF->pdfsimple;
ok($pdf);

# 03 Check if the HTML can be read and produces correct XML
my $filename = "${basedir}test.pdf";
$document = $pdf->Document( $filename );
$document->xml unless ok($document->xml =~
m|^<document>
<attributes>
<filename>t/test.pdf</filename>
<title>NexTrieve notebook paper Trec 2001</title>
</attributes>
<text>
<title>NexTrieve notebook paper Trec 2001</title>
NexTrieve notebook paper Trec 2001
Gordon Clare and Kim Hendrikse|s);

# 04 Check if the encoding of the document is correct
ok($document->encoding,'iso-8859-1');

# 05 Check if we can create a resource object
my $resource = $pdf->Resource;
ok($resource);

# 06 Check if it has the right XML
$resource->xml unless ok($resource->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
<indexcreation>
<attribute name="filename" type="string" key="key-unique" nvals="1"/>
<attribute name="title" type="string" key="notkey" nvals="1"/>
<texttype name="title"/>
</indexcreation>
</ntv:resource>
EOD
