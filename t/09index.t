use Test;
BEGIN { plan tests => 5 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if -e $filename;
}

use NexTrieve qw(Index);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => 1} );
my $version = $ntv->version;

# 02 Create empty index object
my $index = $ntv->Index;
ok($index);

# 03 Check if resource object works
$filename = "$0.resource.xml";
my $resource = $ntv->Resource->write_file( $filename );
$index->Resource( $resource );
ok($index->Resource,$resource);

# 04 Check if creation of index object with resource filename works
$index = $ntv->Index( $filename );
ok(ref($index->Resource),ref($resource));

# 05 Check if creation of index object with parameters works
$index = $ntv->Index( {basedir => '/home/user/nextrieve'} );
ok(ref($index->Resource),ref($resource));
