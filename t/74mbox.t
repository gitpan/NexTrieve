use strict;
use warnings;
use Test;
BEGIN { plan tests => 8 }

use NexTrieve qw(Mbox);

my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
my $mailbox = "${basedir}mailbox";
my $message = "${basedir}message";
unlink( $mailbox );

# 01 Check if we can create a NexTrieve object
my $ntv = NexTrieve->new( {
 RaiseError => 1,
} );
ok($ntv);

# 02 Check if we can create an Mbox object
my $mbox = $ntv->Mbox;
$mbox->Set( {
 conceptualmailbox	=> 'mailbox',
 baseoffset		=> -e $mailbox ? -s _ : 0,
 archive		=> $mailbox,
});
ok($mbox);

# 03 Check if we can index a single mailbox and get a docseq object
my $docseq = $mbox->Docseq( "$message.1" );
ok($docseq);

# 04 Check if we can unlink the single mailbox
ok(unlink( "$message.1" )==1);

# 05 Do the rest of the messages, see if the XML is ok
$mbox->Docseq( $docseq,<$message.*> );
$docseq->xml unless ok($docseq->xml,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>mailbox</mailbox>
<offset>0</offset>
<length>63</length>
</attributes>
<text>
This is message 1
</text>
</document>
<document>
<attributes>
<mailbox>mailbox</mailbox>
<offset>63</offset>
<length>65</length>
</attributes>
<text>
This is message 22
</text>
</document>
<document>
<attributes>
<mailbox>mailbox</mailbox>
<offset>128</offset>
<length>67</length>
</attributes>
<text>
This is message 333
</text>
</document>
</ntv:docseq>
EOD

# 06 Remove the rest of the messages
ok(unlink(<$message.*>)==2);

# 07 Check if the archive is correct
my $archive = $ntv->slurp( $ntv->openfile( $mailbox ) );
warn $archive unless ok($archive,<<EOD);
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

# 08 Remove the archive mailbox
ok(unlink($mailbox)==1);
