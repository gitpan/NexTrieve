# This test depends on the directories "indexdir" and "querylog" left behind
# by previous tests.

use strict;
use warnings;
use Test;

use vars qw($tests $loaded $daemon $number $flag);

BEGIN { $tests = 25; plan tests => $tests }
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

my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
if (-e "${basedir}ntvskip") {
  print "ok $_ # skip NexTrieve not functional\n" foreach 2..$tests;
  exit;
}
my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Check indexdir directory
my $indexdir = "${basedir}indexdir";
ok(-d $indexdir);

# 03 Check resource file
my $resourcexml = "${basedir}resource.xml";
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
$daemon->RaiseError( 0 );
my $pid = $daemon->pid;
$daemon->RaiseError( 1 );
my $skip = $pid ? '' : "NexTrieve server did not start";;
skip($skip,$pid);

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
skip($skip,$errors == 0);
my $md5 = $hitlist->md5;

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
skip($skip,$errors == 0);
unlink( $hitlistxml );

# 09 Stop the daemon
skip($skip,$daemon->stop);

# 10 Check if the pidfile is gone
skip($skip,!-e $daemon->pidfile);

# 11 Check whether MD5's of two hitlists match, skip if no MD5 available
skip(($skip or !$md5),$md5,$hitlist->md5);

# 12 Check if there is a querylogfile
my ($logfile) = <$querylogdir/*>;
skip($skip,$logfile);

# 13 Create a query log object
my $querylog = $ntv->Querylog( $logfile );
skip($skip,$querylog);

# 14 Check first query
$query = $querylog->Query;
skip($skip,($query->query eq 'one' and $query->type eq 'exact'));
$md5 = $query->md5;

# 15 Check second query
$query = $querylog->Query;
skip($skip,($query->query eq 'one' and $query->type eq 'exact'));

# 16 Check whether MD5's of two queries match, skip if no MD5 available
skip(($skip or !$md5),$md5,$query->md5);

# 17 Check third query (there shouldn't be one)
skip($skip,!$querylog->Query);
undef( $querylog );
unlink( <$querylogdir/*> );

# 18 Check if we can start a new daemon
my $port = $ntv->anyport;
skip($skip,$ntv->Daemon( $resource,$port )->start->pid); # lose object now

# 19 Check if we can get the pid from the daemon
$daemon = $ntv->Daemon( $resource,$port );
$pid = $daemon->pid;
skip($skip,$pid);

# 20 Check if can restart the daemon
$daemon->restart;
my $otherpid = $daemon->pid;
skip($skip,($otherpid and $pid != $otherpid));

# 21 Check if we can do an initial speedup
skip($skip,$daemon->initial_speedup);

# 22 Check if we can ping a new daemon
skip($skip,$daemon->ping);

# 23 Check if we can auto shutdown the daemon 
$daemon->auto_shutdown( 1 );
undef( $daemon );
skip($skip,!kill( 15,$otherpid ));

# 24 Create a query log object
$querylog = $ntv->Querylog( (<$querylogdir/*>)[0] );
skip($skip,($querylog and !$querylog->Errors));

# 25 Check first query (is a ping, should be ignored)
skip($skip,$querylog->eof);
