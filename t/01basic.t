use Test;
BEGIN { plan tests => 13 }
END { ok(0) unless $loaded }
use NexTrieve qw(:all);
$loaded = 1;
ok(1);

# 02 Check if we can make the main object
my $ntv = NexTrieve->new( {RaiseError => 1} );
ok($ntv);

# 03 Check if it is the right version
ok($ntv->version,'1.0');

# 04 Check setting of default encoding
$ntv->DefaultInputEncoding( 'utf-8' );
ok($ntv->DefaultInputEncoding,'utf-8');

# 05 Check if encoding was inherited
$ntv->Resource->xml unless ok($ntv->Resource->xml,<<EOD );
<?xml version="1.0" encoding="utf-8"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
</ntv:resource>
EOD

# 06 Check common encoding name error
ok($ntv->_normalize_encoding( 'iso8859-1' ),'iso-8859-1');

# 07 Check common encoding name error
ok($ntv->_normalize_encoding( 'iso_8859_15' ),'iso-8859-15');

# 08 Check common encoding name error
ok($ntv->_normalize_encoding( 'iso-8858-2' ),'iso-8859-2');

# 09 Check common encoding name error
ok($ntv->_normalize_encoding( 'html' ),'iso-8859-1');

# 10 Check common encoding name error
ok($ntv->_normalize_encoding( 'us-ascii' ),'iso-8859-1');

# 11 Check common encoding name error
ok($ntv->_normalize_encoding( 'latin-5' ),'iso-8859-5');

# 12 Check common encoding name error
ok($ntv->_normalize_encoding( 'isolatin-5' ),'iso-8859-5');

# 13 Check common encoding name error
ok($ntv->_normalize_encoding( 'iso-latin-5' ),'iso-8859-5');
