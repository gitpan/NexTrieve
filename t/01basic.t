use Test;
BEGIN { plan tests => 6 }
END { ok(0) unless $loaded }
use NexTrieve qw(:all);
$loaded = 1;
ok(1);

# 02 Check if we can make the main object
my $ntv = NexTrieve->new( {DieOnError => 1} );
ok($ntv);

# 03 Check if it is the right version
ok($ntv->version,'1.0');

# 04 Check if there is a NexTrieve path
ok($ntv->NexTrievePath);

# 05 Check setting of default encoding
$ntv->encoding( 'iso-8859-1' );
ok($ntv->encoding,'iso-8859-1');

# 06 Check if encoding was inherited
ok($ntv->Resource->xml,<<EOD );
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
</ntv:resource>
EOD
