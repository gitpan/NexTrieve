use Test;
BEGIN { plan tests => 14 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if -e $filename;
}

use NexTrieve qw(Docseq Document);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => 1} );
my $version = $ntv->version;

# 02 Create empty docseq file, check version
my $docseq = $ntv->Docseq;
ok( $docseq->version,undef );

# 03 Check if encoding can be set and returned
my $encoding = 'iso-8859-1';
$docseq->encoding( $encoding );
ok( $docseq->encoding,$encoding );

# 04 Obtain XML, version should now be set
my $xml = $docseq->xml;
ok( $docseq->version,$version );

# 05 Check whether empty docseq file comes out ok
ok( $xml,<<EOD );
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
</ntv:docseq>
EOD

# 06 Check if reading XML produces identical XML
$xml =
 qq(<ntv:docseq xmlns:ntv="http://www.nextrieve.com/$version"></ntv:docseq>);
$docseq = $ntv->Docseq( $xml );
ok( $docseq->xml,$xml );

# 07 Check if we can create a file
$filename = "$0.xml";
unlink( $filename ) if -e $filename;
$docseq->write_file( $filename );
ok(-e $filename);

# 08 Check if we can read the file that was just created and has the same result
$docseq->read_file( $filename );
ok($docseq->xml,$xml);

# 09 Check if we can create a new object with the just created file
$docseq = $ntv->Docseq( $filename );
ok($docseq->xml,$xml);

# 10 Check if can be used to update existing docseq file
unlink( $filename );
$docseq->write_file;
ok(-e $filename);

# Initialize trial XML
$ntv->encoding( 'ISO-8859-1' );
$xml = <<EOD;
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/$version">
<document><attributes><id>1</id></attributes></document>
<document><attributes><id>2</id></attributes></document>
<document><attributes><id>3</id></attributes></document>
<document><attributes><id>4</id></attributes></document><document>
<attributes>
<id>5</id>
</attributes>
<text>
élève
</text>
</document></ntv:docseq>
EOD

# 11 Add chunks and see if they come out right
my $document = $ntv->Document( {
 encoding => 'utf-8',
 attribute => [qw(id 5)],
 text => ['','Ã©lÃ¨ve']
} );
$docseq = addchunks( $ntv->Docseq,$document );
ok($docseq->xml,$xml);

# 12 Add chunks, now using streaming mode, explicitely closing the streams
$docseq = addchunks( $ntv->Docseq( {stream => $filename} ) );
$docseq->done;
ok($ntv->Docseq( $filename )->xml,$xml);

# 13 Add chunks, now using streaming mode, letting the object go out of scope
addchunks( $ntv->Docseq( {stream => $filename} ) );
ok($ntv->Docseq( $filename )->xml,$xml);

# 14 Add chunks, to two streams, letting the object go out of scope
addchunks( $ntv->Docseq( {stream => [$filename,"$filename.2"]} ) );
ok($ntv->Docseq( $filename )->xml,$ntv->Docseq( "$filename.2" )->xml);
unlink( "$filename.2" );

# Add chunks of stream for testing
sub addchunks {
my $docseq = shift;
$docseq->add( "<document><attributes><id>1</id></attributes></document>\n" );
$docseq->add( \"<document><attributes><id>2</id></attributes></document>\n" );
$docseq->add( ["<document><attributes><id>3</id></attributes></document>\n"] );
$docseq->add( {document => {attributes => {id => 4}}} );
my $document = shift || $ntv->Document( {
 attribute => [qw(id 5)],
 text => ['','élève']
} );
$docseq->add( $document );
return $docseq;
}
