use strict;
use warnings;
use Test;

use vars qw($loaded $filename);

BEGIN { plan tests => 14 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if -e $filename;
}

use NexTrieve qw(Query);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create empty query file, check version
my $query = $ntv->Query;
ok( $query->version,undef );

# 03 Check if encoding can be set and returned
my $encoding = 'iso-8859-1';
$query->encoding( $encoding );
ok( $query->encoding,$encoding );

# 04 Obtain XML, version should now be set
my $xml = $query->xml;
ok( $query->version,$version );

# 05 Check whether empty query file comes out ok
ok( $xml,<<EOD );
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:query xmlns:ntv="http://www.nextrieve.com/1.0" longform="1">
</ntv:query>
EOD

# 06 Check if reading XML produces identical XML
$xml =
 qq(<ntv:query xmlns:ntv="http://www.nextrieve.com/$version"></ntv:query>);
$query = $ntv->Query( $xml );
$query->xml unless ok($query->xml,$xml);

# 07 Check if simple value setting and returning works
my $string = 'one two three';
$query->query( $string );
ok( $query->query,$string );

# 08 Check if XML is correctly generated with given value
$xml = <<EOD;
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:query xmlns:ntv="http://www.nextrieve.com/$version" longform="1">
$string
</ntv:query>
EOD
$query->xml unless ok($query->xml,$xml);

# 09 Check if creation with method specification works ok
$query = $ntv->Query( {query => $string} );
$query->xml unless ok($query->xml,$xml);

# 10 Check if we can create a file
$filename = "$0.xml";
unlink( $filename ) if $filename;
$query->write_file( $filename );
ok(-e $filename);

# 11 Check if we can read the file that was just created and has the same result
$query->read_file( $filename );
$query->xml unless ok($query->xml,$xml);

# 12 Check if we can create a new object with the just created file
$query = $ntv->Query( $filename );
$query->xml unless ok($query->xml,$xml);

# 13 Check if can be used to update existing query file
unlink( $filename );
$query->write_file;
ok(-e $filename);

# 14 Check if we can create a new object with a set of method specifications
$query = $ntv->Query( {
 constraint             => 'attr1 = 1 &amp; attr2 = 2',
 firsthit               => 1,
 fuzzylevel             => 3,
 highlightlength        => 0,
 id                     => 'id',
 indexname              => 'logical',
 lasthit                => 200,
 qall                   => 'all1',
 qany                   => 'any1 any2',
 qnot                   => 'not1 not2 not3',
 query                  => 'one two three four',
 showattributes         => 1,
 showpreviews           => 1,
 texttypes              => [
                            [qw(type1 101)],
			     qw(type2
                                type3),
                            [qw(* 100)],
                           ],
 totalhits              => 1000,
 type                   => 'exact',
} );

ok(!$query->Errors);
