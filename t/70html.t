use strict;
use warnings;
use Test;

use vars qw(@file $tests);

BEGIN { @file = <t/*.html>; $tests = 3*@file; plan tests => $tests }

eval( 'use Date::Parse ()' );
unless (defined( $Date::Parse::VERSION )) {
  print "ok $_ # skip Module Date::Parse not installed\n" foreach 1..$tests;
  exit;
}

undef( $/ );
#@file = ('t/ls.html');
foreach my $file (@file) {
  my $stderr = content( "$file.stderr" );
  my $exit = system( "$^X script/html2ntvml -i -t 32 -f $file 2>stderr >stdout" );
  ok($exit == 0);
  if (-e 'stderr') {
    foreach my $type (qw(stdout stderr)) {
      my $content = content( $type );
      my $ok = 0;
      foreach (map {content( $_ )} <$file*$type>) {
        last if $ok = ($_ eq $content);
        chop( $_ ); # lose the newline; chomp doesn't work because $/ undeffed
        last if $ok = ($content =~ m#$_#s);
      }
      unless (ok($ok)) {
        warn "*** $file ***\n$content" if $content;
      }
      unlink( $type );
    }
  } else {
    warn content( 'stderr' );
    warn content( 'stdout' );
    last;
  }
}

sub content {
  my $filename = shift;
  my $content = '';
  if (open( IN,$filename )) {
    $content = <IN>;
    close( IN );
  }
  return $content;
}
