# This test depends on the directories "indexdir" and "querylog" left behind
# by previous tests and cleans them up when done.

use Test;
BEGIN { $tests = 4; plan tests => $tests }
END {
 ok(0) unless $loaded;
}

use NexTrieve qw(Index);
$loaded = 1;

unless (NexTrieve::Index->executable( 'ntvopt' )) {
  print "ok $_ # skip 'ntvopt' not executable or not found\n" foreach 1..$tests;
  exit;
}
unless (NexTrieve::Index->executable( 'ntvidx-useopt.sh' )) {
  print "ok $_ # skip 'ntvidx-useopt.sh' not executable or not found\n" foreach 1..$tests;
  exit;
}
ok( 1 );

my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
if (-e "${basedir}ntvskip") {
  print "ok $_ # skip NexTrieve not functional\n" foreach 2..$tests;
  unlink( "${basedir}ntvskip" );
  exit;
}
my $ntv = NexTrieve->new;
my $version = $ntv->version;

# 02 Check indexdir directory
$indexdir = "${basedir}indexdir";
ok(-d $indexdir);

# 03 Check resource file
my $resourcexml = "${basedir}resource.xml";
ok(-e $resourcexml);
my $resource = $ntv->Resource( $resourcexml );

# 04 Check the integrity of the optimized index
$index = $ntv->Index( $resource );
if ($index->optimize) {
  my ($error) = $index->Errors;
  print "ok $_ # skip $error" foreach 4..$tests;
} else {
  ok($index->integrityok);
}

# cleanup everything
sleep( 1 );
#system( "rm -f $resourcexml $indexdir/*; rmdir $indexdir" );
#my $querylog = $resource->querylog;
#system( "rm -f $querylog/*; rmdir $querylog" );
