# This test leaves the directories "indexdir" and "querylog" behind for
# further tests, specifically for searching and daemonising.

use strict;
use warnings;
use Test;

use vars qw($tests $loaded);

BEGIN { $tests = 14; plan tests => $tests }
END { ok(0) unless $loaded }

use NexTrieve qw(Docseq Index);
$loaded = 1;

my($executable,$license,$software,$indexlevel) = NexTrieve::Index->executable;
unless ($executable) {
  print "ok $_ # skip 'ntvindex' not executable or not found\n" foreach 1..$tests;
  exit;
}
ok($software and $indexlevel);

my $ntv = NexTrieve->new( {RaiseError => 1 } );
my $version = $ntv->version;
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';

# 02 Create querylog directory
my $querylog = "${basedir}querylog";
mkdir( $querylog,0777 );
ok(-d $querylog);
system( "rm -f $querylog/*" );

# 03 Set up resource file
my $indexdir = "${basedir}indexdir";
my $resourcexml = "${basedir}resource.xml";
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

# 04 See if creation of Index object is successful
my $index = $ntv->Index( $resource );
ok($index);

# 05 Create indexdir directory and make sure it's empty
system( "rm -rf $indexdir" );
ok($index->mkdir and -d $indexdir);

# 06 Set up indexing XML
my $indexxml = "$indexdir/index.xml";
addchunks( $ntv->Docseq )->write_file( $indexxml );
ok(-e $indexxml);

# 07 See if indexing successful
$index->RaiseError( 0 );
my $exit = $index->index( $indexxml );
$index->RaiseError( 1 );
if ($exit) {
  system( "rm -f $resourcexml $indexdir/*; rmdir $indexdir" );
  system( "rm -f $querylog/*; rmdir $querylog" );
  $ntv->openfile( "${basedir}ntvskip",'>' );
  print "ok $_ # skip NexTrieve not functional\n" foreach 7..$tests;
  exit;
}
ok($exit==0);

# 08 Check if indexing started and completed
my $result = $index->result;
ok($result eq '' or
 ($result =~ m#Indexing "$indexxml" starting# and $result =~ m#Indexing done#));

# 09 Check if there an integrity report can be created
ok($index->integrity);

# 10 Check if we can start incremental updates
$index = $ntv->Index( $resource );
$index->update_start( 1 );
ok(-d "$indexdir.new");

# 11 See if streaming index successful
addchunks( $index->Docseq( $indexxml ) );
$result = $index->result;
ok($result eq '' or
 $result =~ m#Indexing "-" starting#s and $result =~ m#Indexing done#s);

# 12 Check if we can end updates
$index->update_end;
ok(-d "$indexdir.old");
system( "rm -f $indexdir.old/*; rmdir $indexdir.old" );

# 13 Check if the integrity is ok
ok($index->integrityok);

# 14 Check if we can create a resource file from the existing index
$resource = eval{$index->ResourceFromIndex};
my $skip = $resource ? '' : "Could not get <indexcreation> information";
$resource->xml unless skip($skip,$resource || '' ? $resource->xml : '',<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:resource>
<indexdir name="t/indexdir">
<indexcreation>
    <fuzzy accentaction="both"/>
    <exact accentaction="both"/>
    <attribute name="flag" type="flag" key="notkey" nvals="1"/>
    <attribute name="number" type="number" key="keyed" nvals="1"/>
    <attribute name="string" type="string" key="duplicates" nvals="*"/>
    <texttype name="footer"/>
    <texttype name="title"/>
</indexcreation>
</ntv:resource>
EOD

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
