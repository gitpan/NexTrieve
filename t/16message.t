use Test;
BEGIN { $tests = 9; plan tests => $tests }

use NexTrieve qw(Message Resource);

# 01 Check if Mail::Box is available
eval( 'use Mail::Box::Manager' );
unless (defined($Mail::Box::Manager::VERSION)) {
  print "ok $_ # Mail::Box module not available\n" foreach 1..$tests;
  exit;
}
ok($Mail::Box::Manager::VERSION);

# 02 Check if we can create a Mail::Box::Manager object

my $mgr = Mail::Box::Manager->new;
ok($mgr);

# 03 Check if we can create a folder
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
my $folder = $mgr->open( folder => $basedir.'bont.mbox' );
ok($folder);

# 04 Check if we can create a NexTrieve object
my $ntv = NexTrieve->new( {
 RaiseError => 1,
} );
ok($ntv);

# 05 Check if we can create an Mail::Box object
my $message = $ntv->Message( {
 field2attribute        => [
                            [qw(from from string key-duplicate 1)],
                            [qw(subject title string notkey 1)],
                           ],
 field2texttype         => [
                            'From',
                            [qw(Subject title 1000)],
                            'To',
                           ],
} );
ok($message);

# 06 Check if we can index a single mailbox and get a docseq object
my $docseq = $message->Docseq( $folder->messages );
ok($docseq);

# 07 Check if it is what we expected
$docseq->xml unless ok($docseq->xml,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<from>me</from>
<title>before message</title>
</attributes>
<text>
<from>me</from>
<title>before message</title>
<to>you</to>
</text>
</document>
<document>
<attributes>
<from>James Bont</from>
<title>Bont Monthly Newsletter</title>
</attributes>
<text>
<from>James Bont</from>
<title>Bont Monthly Newsletter</title>
<to>me</to>
Welcome to the new look monthly Bont Newsletter 
 
                        Welcome
            to the December issue of the monthly Bont Newsletter. Inside you will find out
            about all the latest
</text>
</document>
<document>
<attributes>
<from>me</from>
<title>after message</title>
</attributes>
<text>
<from>me</from>
<title>after message</title>
<to>you</to>
</text>
</document>
</ntv:docseq>
EOD

# 08 Check if we can create a resource object
my $resource = $message->Resource;
ok($resource);

# 09 Check if it has the right XML
$resource->xml unless ok($resource->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
<indexcreation>
<attribute name="from" type="string" key="key-duplicate" nvals="1"/>
<attribute name="title" type="string" key="notkey" nvals="1"/>
<texttype name="from"/>
<texttype name="title" weight="1000"/>
<texttype name="to"/>
</indexcreation>
</ntv:resource>
EOD
