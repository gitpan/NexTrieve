use strict;
use warnings;
use Test;

use vars qw($loaded $filename);

BEGIN { plan tests => 15 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if defined($filename) and -e $filename;
}

use NexTrieve qw(Resource);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create empty resource file, check version
my $resource = $ntv->Resource;
ok( $resource->version,undef );

# 03 Check if broken encoding can be set and returned
$resource->encoding( 'latin-1' );
ok( $resource->encoding,'iso-8859-1' );

# 04 Obtain XML, version should now be set
my $xml = $resource->xml;
ok( $resource->version,$version );

# 05 Check whether empty resource file comes out ok
ok( $xml,<<EOD );
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
</ntv:resource>
EOD

# 06 Check if reading XML produces identical XML
$xml =
 qq(<ntv:resource xmlns:ntv="http://www.nextrieve.com/$version"></ntv:resource>);
$resource = $ntv->Resource( $xml,'' );
$resource->xml unless ok( $resource->xml,$xml );

# 07 Check if simple value setting and returning works
my $indexdir = '/home/user/nextrieve/index';
$resource->indexdir( $indexdir );
ok( $resource->indexdir,$indexdir );

# 08 Check if XML is correctly generated with given value
$xml = <<EOD;
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/$version">
<indexdir name="$indexdir"/>
</ntv:resource>
EOD
$resource->xml unless ok($resource->xml,$xml);

# 09 Check if creation with method specification works ok
$resource = $ntv->Resource( {indexdir => $indexdir} );
$resource->xml unless ok($resource->xml,$xml);

# 10 Check if we can create a file
$filename = "$0.xml";
unlink( $filename ) if $filename;
$resource->write_file( $filename );
ok(-e $filename);

# 11 Check if we can read the file that was just created and has the same result
$resource->read_file( $filename );
$resource->xml unless ok($resource->xml,$xml);

# 12 Check if we can create a new object with the just created file
$resource = $ntv->Resource( $filename,'filename' );
$resource->xml unless ok($resource->xml,$xml);

# 13 Check if can be used to update existing resource file
unlink( $filename );
$resource->write_file;
ok(-e $filename);

# 14 Check if we can create a new object with a set of method specifications
(my $querylog = $indexdir) =~ s#/index$#/queries#;
$resource = $ntv->Resource( {

 cache          => '10M',
 indexdir       => $indexdir,
 licensefile    => '',
 logfile        => "$indexdir/index.log",

# indexcreation section
 attributes     => [
                    [qw(single string key-unique 1)],
                    [qw(multi1 string key-duplicates)],
                     qw(multi2
                        multi3
                        multi4),
                    [qw(number1 number notkey)],
                     qw(number2),
                    [qw(flag1 flag)],
                     qw(flag2
                        flag3),
                   ],

 texttypes      => [
                    [qw(one 100)],
                     qw(two
                        three
                        four),
                    [qw(five 500)],
                   ],

# indexing section
 unknowntext    => [qw(log default)],
 nestedtext     => [qw(!log inherit)],
 unknownattrs   => 'log',
 nestedattrs    => 'stop',

# searching section
 highlight      => 'b',
 querylog       => $querylog,
 threads        => [50,100,5],
} );

ok(!$resource->Errors);

# 15 check if the XML comes out alright
$resource->xml unless ok($resource->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
<cache size="10M"/>
<indexdir name="/home/user/nextrieve/index"/>
<logfile name="/home/user/nextrieve/index/index.log"/>
<indexcreation>
<attribute name="flag1" type="flag"/>
<attribute name="flag2"/>
<attribute name="flag3"/>
<attribute name="multi1" type="string" key="key-duplicates"/>
<attribute name="multi2"/>
<attribute name="multi3"/>
<attribute name="multi4"/>
<attribute name="number1" type="number" key="notkey"/>
<attribute name="number2"/>
<attribute name="single" type="string" key="key-unique" nvals="1"/>
<texttype name="five" weight="500"/>
<texttype name="four"/>
<texttype name="one" weight="100"/>
<texttype name="three"/>
<texttype name="two"/>
</indexcreation>
<indexing>
<nestedattrs logaction="stop"/>
<nestedtext logaction="!log" indexaction="inherit"/>
<unknownattrs logaction="log"/>
<unknowntext logaction="log" indexaction="default"/>
</indexing>
<searching>
<highlight name="b"/>
<querylog path="/home/user/nextrieve/queries"/>
<threads connector="50" core="5" worker="100"/>
</searching>
</ntv:resource>
EOD
