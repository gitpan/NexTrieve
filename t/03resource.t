use Test;
BEGIN { plan tests => 14 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if -e $filename;
}

use NexTrieve qw(Resource);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => 1} );
my $version = $ntv->version;

# 02 Create empty resource file, check version
my $resource = $ntv->Resource;
ok( $resource->version,undef );

# 03 Check if encoding can be set and returned
my $encoding = 'iso-8859-1';
$resource->encoding( $encoding );
ok( $resource->encoding,$encoding );

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
$resource = $ntv->Resource( $xml );
ok( $resource->xml,$xml );

# 07 Check if simple value setting and returning works
my $basedir = '/home/user/nextrieve';
$resource->basedir( $basedir );
ok( $resource->basedir,$basedir );

# 08 Check if XML is correctly generated with given value
$xml = <<EOD;
<ntv:resource xmlns:ntv="http://www.nextrieve.com/$version">
<basedir name="$basedir"/>
</ntv:resource>
EOD
ok($resource->xml,$xml);

# 09 Check if creation with method specification works ok
$resource = $ntv->Resource( {basedir => $basedir} );
ok($resource->xml,$xml);

# 10 Check if we can create a file
$filename = "$0.xml";
unlink( $filename ) if $filename;
$resource->write_file( $filename );
ok(-e $filename);

# 11 Check if we can read the file that was just created and has the same result
$resource->read_file( $filename );
ok($resource->xml,$xml);

# 12 Check if we can create a new object with the just created file
$resource = $ntv->Resource( $filename );
ok($resource->xml,$xml);

# 13 Check if can be used to update existing resource file
unlink( $filename );
$resource->write_file;
ok(-e $filename);

# 14 Check if we can create a new object with a set of method specifications
my $indexdir = "$basedir/index";
$resource = $ntv->Resource( {

 basedir        => $basedir,
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
 querylog       => "$basedir/queries",
 threads        => [50,100,5],
} );

ok(!$resource->Errors);
