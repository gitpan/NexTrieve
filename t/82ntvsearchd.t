# This test depends on the directories "indexdir" and "querylog" left behind
# by previous tests and cleans them up when done.

use Test;
BEGIN { $tests = 23; plan tests => $tests }
END {
 ok(0) unless $loaded;
 $daemon->stop if $daemon and $daemon->pid;
}

use NexTrieve qw(Daemon Replay);
$loaded = 1;

unless (NexTrieve::Daemon->executable) {
  print "ok $_ # skip 'ntvsearchd' not executable or not found\n" foreach 1..$tests;
  exit;
}
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => 1} );
my $version = $ntv->version;
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';

# 02 Check indexdir directory
$indexdir = "${basedir}indexdir";
ok(-d $indexdir);

# 03 Check resource file
my $resourcexml = "$indexdir/resource.xml";
ok(-e $resourcexml);
my $resource = $ntv->Resource( $resourcexml );

# 04 Check if the query log directory is there and clean it out
my $querylogdir = $resource->querylog;
ok(-d $querylogdir);
system( "rm -rf $querylogdir/*" );

# 05 Check the integrity of the index
$daemon = $ntv->Daemon( $resource,$ntv->anyport );
ok($daemon->integrityok);

# 06 Start the search daemon
$daemon->start;
ok($daemon->pid);

# 07 Perform a simple search
my $search = $ntv->Search( $daemon );
my $query = $ntv->Query( {
 type	=> 'exact',
 query	=> 'one',
});
my $hitlist = $search->Hitlist( $query );
my $firsthit = $hitlist->firsthit;
my $lasthit = $hitlist->lasthit;
my $errors = ($lasthit != 10);
foreach ($firsthit..$lasthit) {
  my $hit = $hitlist->Hit( $_ );
  my ($number,$flag) = $hit->attributes( qw(number flag) );
  $flag ||= 0; # fix undefined warning in next line
  $errors++ if $number != $_ or $flag != ($_ & 1);
}
ok($errors == 0);
$md5 = $hitlist->md5;

# 08 save the hitlist in an external file and process that
my $hitlistxml = "${basedir}hitlist.xml";
$search->Hitlist( $query,$hitlistxml );
$hitlist = $ntv->Hitlist( $hitlistxml );
$errors = ($hitlist->lasthit != 10);
foreach my $hit ($hitlist->Hits) {
  my $ordinal = $hit->ordinal;
  $hit->attributes( qw(number flag) );
  $number ||= ''; # fix warning about being used only once
  $flag ||= 0; # fix used once warning and undefined warning
  $errors++ if $number != $ordinal or $flag != ($ordinal & 1);
}
ok($errors == 0);
unlink( $hitlistxml );

# 09 Stop the daemon
ok($daemon->stop);

# 10 Check if the pidfile is gone
ok(!-e $daemon->pidfile);

# 11 Check whether MD5's of two hitlists match, skip if no MD5 available
skip(!$md5,$md5,$hitlist->md5);

# 12 Check if there is a querylogfile
my ($logfile) = <$querylogdir/*>;
ok($logfile);

# 13 Create a query log object
my $querylog = $ntv->Querylog( $logfile );
ok($querylog);

# 14 Check first query
$query = $querylog->Query;
ok($query->query eq 'one' and $query->type eq 'exact');
$md5 = $query->md5;

# 15 Check second query
$query = $querylog->Query;
ok($query->query eq 'one' and $query->type eq 'exact');

# 16 Check whether MD5's of two queries match, skip if no MD5 available
skip(!$md5,$md5,$query->md5);

# 17 Check third query (there shouldn't be one)
ok(!$querylog->Query);
undef( $querylog );
unlink( <$querylogdir/*> );

# 18 Check if we can start a new daemon
my $port = $ntv->anyport;
ok(!$ntv->Daemon( $resource,$port )->start); # lose the object right away

# 19 Check if we can ping a new daemon
$daemon = $ntv->Daemon( $resource,$port );
ok($daemon->ping);

# 20 Check if we can get the pid from the daemon
my $pid = $daemon->pid;
ok($pid);

# 21 Check if we can auto shutdown the daemon 
$daemon->auto_shutdown( 1 );
undef( $daemon );
ok(!kill( 15,$pid ));

# 22 Create a query log object
$querylog = $ntv->Querylog( <$querylogdir/*> );
ok($querylog and !$querylog->Errors);

# 23 Check first query (is a ping, should be ignored)
ok(!$querylog->Query);

# cleanup everything
sleep( 1 );
system( "rm -rf $indexdir" );
system( "rm -rf $querylogdir" );
