use strict;
use warnings;
use Test;

use vars qw($loaded $filename);

BEGIN { plan tests => 7 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if -e $filename;
}

use NexTrieve qw(Search);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create empty search object
my $search = $ntv->Search;
ok($search);

# 03 Check if port setting works
$search->Resource( 3333 );
ok($search->Resource,'3333');

# 04 Check if server:port setting works
$search->Resource( 'localhost:3333' );
ok($search->Resource,'localhost:3333');

# 05 Check if resource object works
$filename = "$0.resource.xml";
my $resource = $ntv->Resource->write_file( $filename );
$search->Resource( $resource );
ok($search->Resource,$resource);

# 06 Check if creation of search object with resource filename works
$search = $ntv->Search( $filename );
ok(ref($search->Resource),ref($resource));

# 07 Check if creation of search object with parameters works
$search = $ntv->Search( {indexdir => '/home/user/nextrieve/index'} );
ok(ref($search->Resource),ref($resource));
