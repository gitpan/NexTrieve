use Test;
BEGIN { plan tests => 7 }
END {
  ok(0) unless $loaded;
  unlink( $filename ) if -e $filename;
}

use NexTrieve qw(Querylog);
$loaded = 1;
ok( 1 );

my $ntv = NexTrieve->new( {DieOnError => 1} );
my $version = $ntv->version;

# 02 Create empty querylog object
my $querylog = $ntv->Querylog;
ok($querylog);

# Initialize stuff
$filename = "$0.querylog";
my @localtime = ('Thu Jan 17 11:26:34 2002','Thu Jan 17 11:26:43 2002');
my @query = ('chla','hitec');

my $logfile = <<EOD;
$localtime[0]
<ntv:query
 xmlns:ntv="http://www.nextrieve.com/1.0"
 type="fuzzy" fuzzylevel="1"
 displayedhits="200"
 totalhits="1000"
 >
<constraint>(!typenum in (181,13,32,182,15,184,183,185,17,34,31,186))</constrain
t>
<texttype name="name" weight="1000"/>
<texttype name="*" weight="100"/>

$query[0]
</ntv:query>
$localtime[1]
<ntv:query
 xmlns:ntv="http://www.nextrieve.com/1.0"
 type="fuzzy" fuzzylevel="1"
 displayedhits="200"
 totalhits="1000"
 >
<constraint>(typenum in (11))</constraint>
<texttype name="name" weight="1000"/>
<texttype name="*" weight="100"/>

$query[1]
</ntv:query>
EOD

my $handle = $ntv->openfile( $filename,'>' );
print $handle $logfile; close( $handle );

use Carp ();
$SIG{__DIE__} = \&Carp::confess;

# 03 create querylog object from file
$querylog = $ntv->Querylog( $filename );
ok($querylog);

# 04 obtain first query object, see if successful
my ($query,$localtime) = $querylog->Query;
ok($query);

# 05 check if values ok of first query
ok($localtime eq $localtime[0] and $query->query eq $query[0]);

# 06 check if values ok of first query
($query,$localtime) = $querylog->Query;
ok($localtime eq $localtime[1] and $query->query eq $query[1]);

# 07 check if no more queries
($query,$localtime) = $querylog->Query;
ok($query,undef);
