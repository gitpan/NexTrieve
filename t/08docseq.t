use Test;
BEGIN { plan tests => 18 }
END {
  ok(0) unless $loaded;
  unlink( @filename ) if @filename;
}

use NexTrieve qw(Docseq Document);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create empty docseq file, check version
my $docseq = $ntv->Docseq;
ok( $docseq->version,undef );

# 03 Check if encoding is set correctly
ok( $docseq->encoding,'utf-8' );

# 04 Obtain XML, version should now be set
my $xml = $docseq->xml;
ok( $docseq->version,$version );

# 05 Check whether empty docseq file comes out ok
ok( $xml,<<EOD );
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
</ntv:docseq>
EOD

# 06 Check if reading XML produces identical XML
$xml =
 qq(<ntv:docseq xmlns:ntv="http://www.nextrieve.com/$version"></ntv:docseq>);
$docseq = $ntv->Docseq( $xml );
$docseq->xml unless ok( $docseq->xml,$xml );

# 07 Check if we can create a file
$filename = "$0.xml";
unlink( $filename ) if -e $filename;
$docseq->write_file( $filename );
ok(-e $filename);
push( @filename,$filename ); # schedule for deletion

# 08 Check if we can read the file that was just created and has the same result
$docseq->read_file( $filename );
$docseq->xml unless ok($docseq->xml,$xml);

# 09 Check if we can create a new object with the just created file
$docseq = $ntv->Docseq( $filename );
$docseq->xml unless ok($docseq->xml,$xml);

# 10 Check if can be used to update existing docseq file
unlink( $filename );
$docseq->write_file;
ok(-e $filename);

# Initialize trial XML
$ntv->DefaultInputEncoding( 'ISO-8859-1' );
$xml = <<EOD;
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
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
 encoding => 'iso-8859-1',
 attribute => [qw(id 5)],
 text => ['','�l�ve']
} );
$docseq = addchunks( $ntv->Docseq,$document );
$docseq->xml unless ok($docseq->xml,$xml);

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
push( @filename,"$filename.2" ); #schedule for deletion

# Add chunks of stream for testing
sub addchunks {
my $docseq = shift;
$docseq->add( "<document><attributes><id>1</id></attributes></document>\n" );
$docseq->add( \"<document><attributes><id>2</id></attributes></document>\n" );
$docseq->add( ["<document><attributes><id>3</id></attributes></document>\n"] );
$docseq->add( {document => {attributes => {id => 4}}} );
my $document = shift || $ntv->Document( {
 attribute => [qw(id 5)],
 text => ['','�l�ve']
} );
$docseq->add( $document );
return $docseq;
}

# 15 Create list of files
my @list;
foreach (1..5) {
  my $handle = $ntv->openfile( $filename = "$0.$_.xml",'>' );
  print $handle <<EOD;
<?xml version="1.0" encoding="iso-8859-1"?>
<document>
 <attributes><id>$_</id></attributes>
 <text>�l�ve</text>
</document>
EOD
  close( $handle );
  push( @list,$filename );
}
ok(-e $filename);
push( @filename,@list ); #schedule for deletion

# 16 Create a docseq for the list of files and check result
$docseq = $ntv->Docseq->files( @list );
$docseq->xml unless ok($docseq->xml,$xml = <<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
 <attributes><id>1</id></attributes>
 <text>élève</text>
</document>
<document>
 <attributes><id>2</id></attributes>
 <text>élève</text>
</document>
<document>
 <attributes><id>3</id></attributes>
 <text>élève</text>
</document>
<document>
 <attributes><id>4</id></attributes>
 <text>élève</text>
</document>
<document>
 <attributes><id>5</id></attributes>
 <text>élève</text>
</document>
</ntv:docseq>
EOD

# 17 See if we can use the docseq script
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
$handle = $ntv->openfile( "$^X script/docseq -f @list |");
ok($handle);

# 18 See if it creates the right docseq data
ok($ntv->slurp( $handle ),$xml);
