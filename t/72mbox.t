use Test;
BEGIN { plan tests => 15 }

undef $/;

my $script = "$^X script/mailbox2ntvml";
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
my $mailbox = "${basedir}mailbox";
my $message = "${basedir}message";

unlink( $mailbox );

# 01 Create the necessary files
foreach (1..3) {
  open( OUT,">$message.$_" ) || die "$message.$_: $!";
  $_ = $_ x $_;
  print OUT <<EOD;
From me
From: me
To: you
Subject: Message $_

This is message $_
EOD
  close( OUT );
}
ok(@{[<$message.*>]}==3);

# 02 Do the first script
ok(!system( "$script -c $mailbox -o $mailbox -f $message.1 2>stderr >stdout" ));

# 03 Check the STDERR output
my $stderr = content( 'stderr' );
warn $stderr unless ok($stderr eq '' or
                       $stderr =~ m#Cannot decode.*?install MIME#
);

# 04 Check the STDOUT output
my $stdout = content( 'stdout' );
warn $stdout unless ok($stdout,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>t/mailbox</mailbox>
<offset>0</offset>
<length>63</length>
<from>me</from>
<subject>Message 1</subject>
</attributes>
<text>
<subject>Message 1</subject>
This is message 1
</text>
</document>
</ntv:docseq>
EOD

# 05 Move the message 1 to the mailbox
ok(!system( "cat $message.1 >>$mailbox" ));

# 06 Process message 2
ok(!system( "$script -c $mailbox -o $mailbox -f $message.2 2>stderr >stdout" ));

# 07 Check the STDERR output
$stderr = content( 'stderr' );
warn $stderr unless ok($stderr eq '' or
                       $stderr =~ m#Cannot decode.*?install MIME#
);

# 08 Check the STDOUT output
$stdout = content( 'stdout' );
warn $stdout unless ok($stdout,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>t/mailbox</mailbox>
<offset>63</offset>
<length>65</length>
<from>me</from>
<subject>Message 22</subject>
</attributes>
<text>
<subject>Message 22</subject>
This is message 22
</text>
</document>
</ntv:docseq>
EOD

# 09 Move the message 2 to the mailbox
ok(!system( "cat $message.2 >>$mailbox" ));

# 10 Process message 3
ok(!system( "$script -c $mailbox -o $mailbox -f $message.3 2>stderr >stdout" ));

# 11 Check the STDERR output
$stderr = content( 'stderr' );
warn $stderr unless ok($stderr eq '' or
                       $stderr =~ m#Cannot decode.*?install MIME#
);

# 12 Check the STDOUT output
$stdout = content( 'stdout' );
warn $stdout unless ok($stdout,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>t/mailbox</mailbox>
<offset>128</offset>
<length>67</length>
<from>me</from>
<subject>Message 333</subject>
</attributes>
<text>
<subject>Message 333</subject>
This is message 333
</text>
</document>
</ntv:docseq>
EOD

# 13 Move the message 3 to the mailbox
ok(!system( "cat $message.3 >>$mailbox" ));

# 14 Check the mailbox now
$stdout = content( $mailbox );
warn $stdout unless ok($stdout,<<EOD);
From me
From: me
To: you
Subject: Message 1

This is message 1
From me
From: me
To: you
Subject: Message 22

This is message 22
From me
From: me
To: you
Subject: Message 333

This is message 333
EOD

# 15 Remove all the files that were created
ok(unlink( $mailbox,qw(stdout stderr) )==3);

sub content {
  my $filename = shift;
  my $content = '';
  if (open( IN,$filename )) {
    $content = <IN>;
    close( IN );
  }
  return $content;
}
