# This test leaves the directories "indexdir" and "querylog" behind for
# further tests, specifically for searching and daemonising.

use Test;
BEGIN { $tests = 10; plan tests => $tests }
END { ok(0) unless $loaded }

use NexTrieve qw(Docseq Index);
$loaded = 1;

unless (NexTrieve::Index->executable) {
  print "ok $_ # skip 'ntvindex' not executable or not found\n" foreach 1..$tests;
  exit;
}
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => sub {print "whoopee"} } );
my $version = $ntv->version;
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';

# 02 Create indexdir directory

$indexdir = "${basedir}indexdir";
mkdir( $indexdir,0700 );
ok(-d $indexdir);
system( "rm -rf $indexdir/*" );

# 03 Create querylog directory

$querylog = "${basedir}querylog";
mkdir( $querylog,0700 );
ok(-d $querylog);
system( "rm -rf $querylog/*" );

# 04 Set up resource file
my $resourcexml = "$indexdir/resource.xml";
my $resource = $ntv->Resource( {
 indexdir	=> $indexdir,
 querylog	=> $querylog,
 attributes	=> [
		    [qw(number number key-unique 1)],
		    [qw(flag flag notkey 1)],
		    [qw(string string key-duplicates *)],
		   ],
 texttypes	=> [qw(title footer)],
});
$resource->write_file( $resourcexml );
ok(-e $resourcexml);

# 05 Set up indexing XML
my $indexxml = "$indexdir/index.xml";
addchunks( $ntv->Docseq )->write_file( $indexxml );
ok(-e $indexxml);

# 06 See if direct index successful
my $index = $ntv->Index( $resource,$indexxml );
ok($index);

# 07 Check if indexing started and completed
my $result = $index->result;
ok($result =~ m#Indexing "$indexxml" starting# and
   $result =~ m#Indexing done#);

# 08 Check if there is an integrity report, remove contents afterwards
ok($index->integrity);
system( "rm -rf $indexdir/*" );
$resource->write_file;

# 09 See if streaming index successful
$index = $ntv->Index( $resource );
addchunks( $index->Docseq( $indexxml ) );
$result = $index->result;
ok($result =~ m#Indexing "-" starting# and
   $result =~ m#Indexing done#);

# 10 Check if the integrity is ok
ok($index->integrityok);


# Add chunks of stream for testing
sub addchunks {
my $docseq = shift;
my %word = qw(
 1 one
 2 two
 3 three
 4 four
 5 five
 6 six
 7 seven
 8 eight
 9 nine
 10 ten
);

foreach( 1..10 ) {
  $docseq->add( {
   document => {
    attributes => {
     number => $_,
     flag => $_ & 1,
     string => join( ' ',@word{1..$_} ),
    },
    text => {
     title => "title of $word{$_}",
     '' => join( ' ',$_,@word{1..$_} ),
     footer => "footer of $word{$_}",
    },
   }
  } );
}
return $docseq;
}
