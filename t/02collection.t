use Test;
BEGIN { plan tests => 6 }
END {
 ok(0) unless $loaded;
 unlink( $filename ) if $filename and -e $filename;
 rmdir( "$directory/$name" ) if $directory and $name and -d "$directory/$name";
 rmdir( $directory ) if $directory;
}

use NexTrieve qw(Collection);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => 1} );
my $version = $ntv->version;

# 02 Create empty collection
$directory = "$0.collection";
my $collection = $ntv->Collection( $directory,1 );
ok(-d $directory);

# 03 Create new mnemonic name with associated resource-file
$name = 'test';
my $resource = $collection->Resource( $name );
$filename = "$directory/$name/$name.res";
ok(-e $filename);

# 04 Check if filename setting is correct
ok($resource->filename,$filename);

# 05 Check version
ok( $resource->version,$version );

# 06 Check whether empty collection file comes out ok
ok( $resource->xml,<<EOD );
<ntv:resource xmlns:ntv="http://www.nextrieve.com/$version">
</ntv:resource>
EOD
