use Test;
BEGIN { plan tests => 9 }
END {
  ok(0) unless $loaded;
  unlink( @filename ) if @filename;
}

use NexTrieve qw(Mbox Resource);
$loaded = 1;
ok( 1 );

eval( 'use Date::Parse ()' );
my $DateParse = defined( $Date::Parse::VERSION ) ?
 '' : "Module Date::Parse not installed";
$DateParse .= "\nModule MIME::Base64 not installed"
 unless defined($MIME::Base64::VERSION);
$DateParse .= "\nModule MIME::QuotedPrint not installed"
 unless defined($MIME::QuotedPrint::VERSION);

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create Mbox object
my $mbox = $ntv->Mbox( {
 field2attribute	=> [
			    [qw(Date published number notkey 1)],
			   ],
 field2texttype		=> [
                            'From',
			    [qw(Subject title 1000)],
			    'To',
			   ],
 attribute_processor	=> [
 			    [qw(published timestamp)],
			   ],
} );
ok($mbox);

# 03 Create a very simple mailbox
my $filename1 = "$0.1.mbox";
my $handle = $mbox->openfile( $filename1,'>' );
print $handle <<EOD foreach 1..5;
From me\@$_.com
From: me
Subject: This is title #$_
To: you

This is message #$_
EOD
close( $handle );
ok(-e $filename1);
push( @filename,$filename1 ); #schedule for deletion

# 04 Process the mailbox and create a docseq out of that
my $docseq = $mbox->Docseq( $filename1 );
$docseq->xml unless ok($docseq->xml,<<EOD );
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>t/14mbox.t.1.mbox</mailbox>
<offset>0</offset>
<length>77</length>
</attributes>
<text>
<from>me</from>
<title>This is title #1</title>
<to>you</to>
This is message #1
</text>
</document>
<document>
<attributes>
<mailbox>t/14mbox.t.1.mbox</mailbox>
<offset>77</offset>
<length>77</length>
</attributes>
<text>
<from>me</from>
<title>This is title #2</title>
<to>you</to>
This is message #2
</text>
</document>
<document>
<attributes>
<mailbox>t/14mbox.t.1.mbox</mailbox>
<offset>154</offset>
<length>77</length>
</attributes>
<text>
<from>me</from>
<title>This is title #3</title>
<to>you</to>
This is message #3
</text>
</document>
<document>
<attributes>
<mailbox>t/14mbox.t.1.mbox</mailbox>
<offset>231</offset>
<length>77</length>
</attributes>
<text>
<from>me</from>
<title>This is title #4</title>
<to>you</to>
This is message #4
</text>
</document>
<document>
<attributes>
<mailbox>t/14mbox.t.1.mbox</mailbox>
<offset>308</offset>
<length>77</length>
</attributes>
<text>
<from>me</from>
<title>This is title #5</title>
<to>you</to>
This is message #5
</text>
</document>
</ntv:docseq>
EOD

# 05 Create a mailbox that is slightly more complicated
my $filename2 = "$0.2.mbox";
$handle = $mbox->openfile( $filename2,'>' );
print $handle q|From someone@somewhere.com  Sun Dec  2 08:51:49 2001
Delivered-To: list@somewhereelse.com
Message-Id: <200112021351.fB2Dpk113795@email.domain.name>
From: Someone <someone@somewhere.com>
To: list <list@somewhereelse.com>
Date: Sun, 2 Dec 2001 23:57:13 +1000
X-Mailer: KMail [version 1.2.9]
MIME-Version: 1.0
Content-Type: Multipart/Mixed;
  boundary="------------Boundary-00=_ERYPH0E9LB5AN7DGG7EI"
Subject: [list] subject of message
Precedence: bulk

--------------Boundary-00=_ERYPH0E9LB5AN7DGG7EI
Content-Type: text/plain;
  charset="iso-8859-1"
Content-Transfer-Encoding: 8bit
Subject: 

Hi,

I've run some tests.

bye,

Someone

--------------Boundary-00=_ERYPH0E9LB5AN7DGG7EI
Content-Type: text/x-diff;
  charset="iso-8859-1";
  name="liblist-1.0.8_ki_0.8.4.diff"
Content-Transfer-Encoding: base64
Content-Description: snapshot diff 
Content-Disposition: attachment; filename="liblist-1.0.8_ki_0.8.4.diff"

T25seSBpbiBsaWJ4c2x0LTEuMC44OiBDT1BZSU5HCk9ubHkgaW4gbGlieHNsdC0xLjAuOF9raTog
TWFrZWZpbGUuY3ZzCk9ubHkgaW4gbGlieHNsdC0xLjAuODogTWFrZWZpbGUuaW4KT25seSBpbiBs
MC44L3hzbHRwcm9jOiBNYWtlZmlsZS5pbgo=

--------------Boundary-00=_ERYPH0E9LB5AN7DGG7EI--

From someoneelse@elsewhere.com  Tue Mar 27 13:21:07 2001
Return-Path: <someoneelse@elsewhere.com>
Delivered-To: list@somewhere.org
Message-ID: <001c01c0b6eb$6c0dfe00$0400a8c0@localnet>
From: "Someone Else <someoneelse@elsewhere.com>
To: <list@somewhere.org>
Date: Tue, 27 Mar 2001 10:26:10 -0800
MIME-Version: 1.0
Content-Type: multipart/mixed;
	boundary="----=_NextPart_000_0018_01C0B6A8.57C28260"
X-Priority: 3
X-MSMail-Priority: Normal
X-Mailer: Microsoft Outlook Express 5.50.4522.1200
X-MimeOLE: Produced By Microsoft MimeOLE V5.50.4522.1200
Subject: [list] a title of a message
X-Mailman-Version: 2.0beta5
Precedence: bulk

This is a multi-part message in MIME format.

------=_NextPart_000_0018_01C0B6A8.57C28260
Content-Type: multipart/alternative;
	boundary="----=_NextPart_001_0019_01C0B6A8.57C28260"


------=_NextPart_001_0019_01C0B6A8.57C28260
Content-Type: text/plain;
	charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

We have encountered a few problems with the current library.

Someone Else
élève

------=_NextPart_001_0019_01C0B6A8.57C28260
Content-Type: text/html;
	charset="iso-8859-1"
Content-Transfer-Encoding: quoted-printable

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
We have encountered a few problems with = the current=20 library.
 
Someone = Else
élève

------=_NextPart_001_0019_01C0B6A8.57C28260--

------=_NextPart_000_0018_01C0B6A8.57C28260
Content-Type: application/octet-stream;
	name="libxslt-0.6.0_patch1"
Content-Transfer-Encoding: quoted-printable
Content-Disposition: attachment;
	filename="libxslt-0.6.0_patch1"

--- functions.c	Mon Mar 19 19:55:05 2001=0A=
+++ functions.c	Tue Mar 27 19:07:49 2001=0A=
@@ -138,7 +138,8 @@=0A=
 	    base =3D xmlNodeGetBase(obj2->nodesetval->nodeTab[0]->doc,=0A=
 				  obj->nodesetval->nodeTab[0]);=0A=
 	} else {=0A=
-	    base =3D xmlNodeGetBase(ctxt->context->doc,=0A=
+	    base =3D xmlNodeGetBase(=0A=
+		((xsltTransformContextPtr)ctxt->context->extra)->style->doc,=0A=
 				  ctxt->context->node);=0A=

------=_NextPart_000_0018_01C0B6A8.57C28260--

|;
close( $handle );
ok(-e $filename2);
push( @filename,$filename2 ); #schedule for deletion

# 06 Create a streaming Docseq and do a conceptual mailbox on it
my $filename3 = "$0.2.docseq";
$mbox->conceptualmailbox( $filename1 );
$mbox->baseoffset( -s $filename1 );
$mbox->Docseq( $ntv->Docseq( {stream => $filename3} ),$filename2 );
ok(-e $filename3);
push( @filename,$filename3 ); #schedule for deletion

# 07 Read the created docseq from file and check
$handle = $ntv->openfile( $filename3 );
my $xml = join( '',<$handle> );
close( $handle );
warn $xml unless skip($DateParse,$xml,q|<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<mailbox>t/14mbox.t.1.mbox</mailbox>
<offset>385</offset>
<length>1154</length>
<published>20011202135713</published>
</attributes>
<text>
<from>Someone &lt;someone@somewhere.com&gt;</from>
<title>[list] subject of message</title>
<to>list &lt;list@somewhereelse.com&gt;</to>
Hi,

I've run some tests.

bye,

Someone

Only in libxslt-1.0.8: COPYING
Only in libxslt-1.0.8_ki: Makefile.cvs
Only in libxslt-1.0.8: Makefile.in
Only in l0.8/xsltproc: Makefile.in
</text>
</document>
<document>
<attributes>
<mailbox>t/14mbox.t.1.mbox</mailbox>
<offset>1539</offset>
<length>2069</length>
<published>20010327182610</published>
</attributes>
<text>
<from>"Someone Else &lt;someoneelse@elsewhere.com&gt;</from>
<title>[list] a title of a message</title>
<to>&lt;list@somewhere.org&gt;</to>
We have encountered a few problems with the current library.

Someone Else
Ã©lÃ¨ve
</text>
</document>
</ntv:docseq>
|);

# 08 Check if we can create a resource file
my $resource = $mbox->Resource;
ok($resource);

# 09 Check if it has the right XML
$resource->xml unless ok($resource->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
<indexcreation>
<attribute name="length" type="number" key="notkey" nvals="1"/>
<attribute name="mailbox" type="string" key="key-duplicate" nvals="1"/>
<attribute name="offset" type="number" key="notkey" nvals="1"/>
<attribute name="published" type="number" key="notkey" nvals="1"/>
<texttype name="from"/>
<texttype name="title" weight="1000"/>
<texttype name="to"/>
</indexcreation>
</ntv:resource>
EOD
