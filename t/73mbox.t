use Test;
BEGIN { plan tests => 14 }

undef $/;

my $script = 'script/mailbox2ntvml';
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
my $mailbox = "${basedir}mailbox";
my $message = "${basedir}message";

unlink( $mailbox );

# 01 Do the first script
ok(!system( "$script -c Mickey -o $mailbox -f $message.1 2>stderr >stdout" ));

# 02 Check the STDERR output
my $stderr = content( 'stderr' );
warn $stderr unless ok($stderr eq '' or
                       $stderr =~ m#Cannot decode.*?install MIME#
);

# 03 Check the STDOUT output
my $stdout = content( 'stdout' );
warn $stdout unless ok($stdout,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>mickey</mailbox>
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

# 04 Move the message 1 to the mailbox
ok(!system( "cat $message.1 >>$mailbox" ));

# 05 Process message 2
ok(!system( "$script -c Mickey -o $mailbox -f $message.2 2>stderr >stdout" ));

# 06 Check the STDERR output
$stderr = content( 'stderr' );
warn $stderr unless ok($stderr eq '' or
                       $stderr =~ m#Cannot decode.*?install MIME#
);

# 07 Check the STDOUT output
$stdout = content( 'stdout' );
warn $stdout unless ok($stdout,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>mickey</mailbox>
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

# 08 Move the message 2 to the mailbox
ok(!system( "cat $message.2 >>$mailbox" ));

# 09 Process message 3
ok(!system( "$script -c Mickey -o $mailbox -f $message.3 2>stderr >stdout" ));

# 10 Check the STDERR output
$stderr = content( 'stderr' );
warn $stderr unless ok($stderr eq '' or
                       $stderr =~ m#Cannot decode.*?install MIME#
);

# 11 Check the STDOUT output
$stdout = content( 'stdout' );
warn $stdout unless ok($stdout,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>mickey</mailbox>
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

# 12 Move the message 3 to the mailbox
ok(!system( "cat $message.3 >>$mailbox" ));

# 13 Check the mailbox now
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

# 14 Remove all the files that were created
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
