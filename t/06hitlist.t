use Test;
BEGIN { plan tests => 26 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if -e $filename;
}

use NexTrieve qw(Hitlist);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create empty hitlist file, check version
my $hitlist = $ntv->Hitlist;
ok( $hitlist->version,undef );

# 03 Check if encoding can be set and returned
my $encoding = 'iso-8859-1';
$hitlist->encoding( $encoding );
ok( $hitlist->encoding,$encoding );

# 04 Obtain XML, version should now be set
my $xml = $hitlist->xml;
ok( $hitlist->version,$version );

# 05 Check whether empty hitlist file comes out ok
ok( $xml,<<EOD );
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:hitlist xmlns:ntv="http://www.nextrieve.com/1.0">
</ntv:hitlist>
EOD

# 06 Check if reading XML produces identical XML
$xml =
 qq(<ntv:hitlist xmlns:ntv="http://www.nextrieve.com/$version"></ntv:hitlist>);
$hitlist = $ntv->Hitlist( $xml );
$hitlist->xml unless ok( $hitlist->xml,$xml );

# 07 Check if we can create a file
$filename = "$0.xml";
unlink( $filename ) if $filename;
$hitlist->write_file( $filename );
ok(-e $filename);

# 08 Check if we can read the file that was just created and has the same result
$hitlist->read_file( $filename );
$hitlist->xml unless ok($hitlist->xml,$xml);

# 09 Check if we can create a new object with the just created file
$hitlist = $ntv->Hitlist( $filename );
$hitlist->xml unless ok($hitlist->xml,$xml);

# 10 Check if can be used to update existing file
unlink( $filename );
$hitlist->write_file;
ok(-e $filename);

# Create an "actual" result
$xml = <<EOD;
<ntv:hitlist xmlns:ntv="http://www.nextrieve.com/1.0">
<header firsthit="1" displayedhits="2" totalhits="3">
 <admin>administrative\@contact.com</admin>
 <error>This is an error</error>
 <warning>This is the first warning</warning>
 <warning>This is the second warning</warning>
</header>
<hit docid="111" score="1111">
 <preview><b>one</b> two three four</preview>
 <attributes>
  <attr1>1001111</attr1>
  <attr2>2001111</attr2>
 </attributes>
</hit>
<hit docid="22" score="222">
 <preview>one <b>two</b> three four</preview>
 <attributes>
  <attr1>1002222</attr1>
  <attr1>1102222</attr1>
  <attr2>2002222</attr2>
 </attributes>
</hit>
</ntv:hitlist>
EOD
$hitlist = $ntv->Hitlist( $xml );

# 11 Check if we have firsthit ok
ok($hitlist->firsthit,1);

# 12 Check if we have lasthit ok
ok($hitlist->lasthit,2);

# 13 Check if we have displayedhits ok
ok($hitlist->displayedhits,2);

# 14 Check if we have totalhits ok
ok($hitlist->totalhits,3);

# 15 Check if we can obtain the admin
ok($hitlist->admin,'administrative@contact.com');

# 16 Check if the errors arrived ok
my @error = $hitlist->errors;
ok(@error,1);

# 17 Check if the text of the error is ok
ok($error[0],'This is an error');

# 18 Check if the warnings arrived ok
my @warning = $hitlist->warnings;
ok(@warning,2);

# 19 Check if the text of the warning is ok
ok($warning[0],'This is the first warning');

# 20 check if we have the correct number of hits
my @hit = $hitlist->Hits;
ok(@hit,2);

# 21 Check if we can obtain the preview from a hit
ok($hit[0]->preview,'<b>one</b> two three four');

# 22 Check if we can get a specific hit
my $hit = $hitlist->Hit( 2 );
ok($hit);

# 23 Check if we can get a lot of info at one time
$hit->Get( qw(docid score) );
ok($docid and $docid == 22 and $score and $score == 222);

# 24 Check if we can get the attributes in one go
$hit->attributes( qw(attr1 attr2) );
ok(@attr1 == 2 and @attr2 == 1);

# 25 Check if the value of the attributes are right
ok($attr1[0] == 1002222 and $attr1[1] = 1102222 and $attr2 == 2002222);

# 26 Check if reading XML produces identical XML
$hitlist->xml unless ok( $hitlist->xml,$xml );
