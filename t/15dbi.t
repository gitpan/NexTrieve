use Test;
BEGIN { $tests = 7; plan tests => $tests }
END {
  ok(0) unless $loaded;
  $dbh->do( "DROP TABLE $table" ) if $dbh and $table;
}

use NexTrieve qw(DBI Resource);
$loaded = 1;

my $message = '';
eval('use DBI;');
$message = "DBI Module not available" unless defined($DBI::VERSION);

$dbh = '';
unless ($message) {
  $dbh = DBI->connect(
   "DBI:mysql:database=test;host=localhost",
   "test",
   '',
   {
    PrintError => 0,
   }
  );
  $message = $DBI::errstr = $DBI::errstr unless $dbh;
}

($table = "nextrievedbi$NexTrieve::VERSION") =~ s#\W##g;
unless ($message) {
  $dbh->do( qq(CREATE TABLE $table (
              ID INT NOT NULL,
              title VARCHAR(255) NOT NULL,
              taxt TEXT NOT NULL
             )) );

  foreach (1..5) {
    $message = $dbh->errstr unless
     $dbh->do( qq(INSERT INTO $table VALUES(
      $_,
      'This is the title of record #$_',
      'The text of record #$_: �l�ve'
     )) );
    last if $message;
  }
}

my $select = qq(SELECT ID as id,title,taxt as text FROM $table);
my $sth = '';
unless ($message) {
  $message = $dbh->errstr unless $sth = $dbh->prepare( $select );
}

unless ($message) {
  $message = $dbh->errstr unless $sth->execute;
}

if ($message) {
  print "ok $_ # $message\n" foreach 1..$tests;
  exit;
}

# 01 Create the NexTrieve object
my $ntv = NexTrieve->new( {RaiseError => 1 } );
ok($ntv);

# 02 Create the NexTrieve DBI object
my $dbi = $ntv->DBI( {
 field2attribute => [
  [qw(id id number key-unique 1)],
  [qw(title title string notkey 1)],
 ],

 field2texttype => [qw(title)],
 
} );
ok($dbi);

# 03 Create the Docseq
my $docseq = $dbi->Docseq( $sth );
ok($docseq);

# 04 See if the docseq is correct
my $xml = <<EOD;
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<id>1</id>
<title>This is the title of record #1</title>
</attributes>
<text>
<title>This is the title of record #1</title>
The text of record #1: élève
</text>
</document>
<document>
<attributes>
<id>2</id>
<title>This is the title of record #2</title>
</attributes>
<text>
<title>This is the title of record #2</title>
The text of record #2: élève
</text>
</document>
<document>
<attributes>
<id>3</id>
<title>This is the title of record #3</title>
</attributes>
<text>
<title>This is the title of record #3</title>
The text of record #3: élève
</text>
</document>
<document>
<attributes>
<id>4</id>
<title>This is the title of record #4</title>
</attributes>
<text>
<title>This is the title of record #4</title>
The text of record #4: élève
</text>
</document>
<document>
<attributes>
<id>5</id>
<title>This is the title of record #5</title>
</attributes>
<text>
<title>This is the title of record #5</title>
The text of record #5: élève
</text>
</document>
</ntv:docseq>
EOD
$docseq->xml unless ok($docseq->xml,$xml);

# 05 See if the dbi2ntvml script works
my $scriptxml = $ntv->slurp( $ntv->openfile(
 "script/dbi2ntvml -a id title -t title -c 'DBI:mysql:database=test;host=localhost' -u 'test' -p '' -s '$select'|" ) );
warn $scriptxml || 'No XML returned' unless ok($scriptxml,$xml);

# 06 Check if we can create a resource object
my $resource = $dbi->Resource;
ok($resource);

# 07 Check if it has the right XML
$resource->xml unless ok($resource->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
<indexcreation>
<attribute name="id" type="number" key="key-unique" nvals="1"/>
<attribute name="title" type="string" key="notkey" nvals="1"/>
<texttype name="title"/>
</indexcreation>
</ntv:resource>
EOD
