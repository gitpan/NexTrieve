use Test;
BEGIN { plan tests => 7 }
END {
 ok(0) unless $loaded;
 unlink( $filename ) if $filename and -e $filename;
 rmdir( "$directory/$name" ) if $directory and $name and -d "$directory/$name";
 rmdir( $directory ) if $directory;
}

use NexTrieve qw(Collection);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( [RaiseError => 1] );
my $version = $ntv->version;

# 02 Create empty collection
$directory = "$0.collection";
my $collection = $ntv->Collection( $directory,1 );
ok(-d $directory);

# 03 Create new index
$name = 'test';
my $index = $collection->Index( $name,1 );
ok(-d "$directory/$name");

# 04 Create resource file in new index
my $resource = $index->Resource;
$filename = "$directory/$name/$name.res";
ok(-e $filename);

# 05 Check if filename setting is correct
ok($resource->filename,$filename);

# 06 Check version
ok( $resource->version,$version );

# 07 Check whether empty collection file comes out ok
$resource->xml unless ok( $resource->xml,<<EOD );
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/$version">
</ntv:resource>
EOD
