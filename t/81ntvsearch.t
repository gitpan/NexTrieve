# This test depends on the directories "indexdir" and "querylog" left behind
# by previous tests.

use Test;
BEGIN { $tests = 6; plan tests => $tests }
END { ok(0) unless $loaded }

use NexTrieve qw(Search Query);
$loaded = 1;

my($executable,$license,$software,$indexlevel) = NexTrieve::Search->executable;
unless ($executable) {
  print "ok $_ # skip 'ntvsearch' not executable or not found\n" foreach 1..$tests;
  exit;
}
ok($software and $indexlevel);

my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
if (-e "${basedir}ntvskip") {
  print "ok $_ # skip NexTrieve not functional\n" foreach 2..$tests;
  exit;
}
my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Check indexdir directory
$indexdir = "${basedir}indexdir";
ok(-d $indexdir);

# 03 Check querylog directory
$querylog = "${basedir}querylog";
ok(-d $querylog);

# 04 Check resource file
my $resourcexml = "${basedir}resource.xml";
ok(-e $resourcexml);
my $resource = $ntv->Resource( $resourcexml );

# 05 Perform a simple search
my $search = $ntv->Search( $resource );
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

# 06 save the hitlist in an external file and process that
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
