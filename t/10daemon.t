use Test;
BEGIN { plan tests => 7 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if -e $filename;
}

use NexTrieve qw(Daemon);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create empty daemon object
my $daemon = $ntv->Daemon;
ok($daemon);

# 03 Check if resource object works
$filename = "$0.resource.xml";
my $resource = $ntv->Resource->write_file( $filename );
$daemon->Resource( $resource );
ok($daemon->Resource,$resource);

# 04 Check if creation of daemon object with resource filename works
$daemon = $ntv->Daemon( $filename );
ok(ref($daemon->Resource),ref($resource));

# 05 Check if creation of daemon object with method hash works
$daemon = $ntv->Daemon( $resource,{indexdir => '/home/user/nextrieve'} );
ok(ref($daemon->Resource),ref($resource));

# 06 Check if creation of daemon object with server:port works
$daemon = $ntv->Daemon( $resource,'localhost:3333' );
ok(ref($daemon->Resource),ref($resource));

# 07 Check if creation of daemon object with port and method hash works
$daemon = $ntv->Daemon( $resource,3333,{indexdir => '/home/user/nextrieve'} );
ok(ref($daemon->Resource),ref($resource));
