use strict;
use warnings;
use Test;

use vars qw($loaded @filename);

BEGIN { plan tests => 16 }
END {
  ok(0) unless $loaded;
  unlink( @filename ) if @filename;
}

use NexTrieve qw(RFC822 Resource);
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

# 02 Create empty RFC822 object
my $rfc822 = $ntv->RFC822( {
 field2attribute	=> [
			    [qw(id id string key-unique 1)],
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
ok($rfc822);

# 03 Create a very simple document from an RFC822 stream
my $document = $rfc822->Document( <<EOD );
From: me
Subject: This is a title
To: you

This is the message
EOD
$document->xml unless ok($document->xml,<<EOD );
<document>
<text>
<from>me</from>
<title>This is a title</title>
<to>you</to>
This is the message
</text>
</document>
EOD

# 04 Create an external file that is slightly more complicated
my $filename = "$0.1.message";
my $handle = $rfc822->openfile( $filename,'>' );
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

|;
close( $handle );
ok(-e $filename);
push( @filename,$filename ); #schedule for deletion

# 05 Check if the RFC822 can be read and produces correct XML
$document = $rfc822->Document( $filename );
skip($DateParse,$document->xml,q|<document>
<attributes>
<published>20011202135713</published>
<id>t/13rfc822.t.1.message</id>
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
|);

# 06 Check if the encoding of the document is correct
skip($DateParse,$document->encoding,'iso-8859-1');

# 07 Create an external file that has recursive parts
$filename = "$0.2.message";
$handle = $rfc822->openfile( $filename,'>' );
my $message = q|From someoneelse@elsewhere.com  Tue Mar 27 13:21:07 2001
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
print $handle $message;
close( $handle );
ok(-e $filename);
push( @filename,$filename ); #schedule for deletion

# Add extra attributes to the document, using refs to the variables
my $offset = 0;
my $length = length($message);
$rfc822->extra_attribute (
 [\$offset,'offset'],
 [\$length,'length'],
);

# 08 Check if the RFC822 message can be read and produces correct XML
$document = $rfc822->Document( "file://$filename",'url' );
warn $document->xml unless skip($DateParse,$document->xml,<<EOD);
<document>
<attributes>
<offset>$offset</offset>
<length>$length</length>
<published>20010327182610</published>
<id>t/13rfc822.t.2.message</id>
</attributes>
<text>
<from>"Someone Else &lt;someoneelse\@elsewhere.com&gt;</from>
<title>[list] a title of a message</title>
<to>&lt;list\@somewhere.org&gt;</to>
We have encountered a few problems with the current library.

Someone Else
élève
</text>
</document>
EOD

# 09 Check if the encoding of the document is correct
ok($document->encoding,'iso-8859-1');

# 10 Create an external file that has HTML parts without text
$filename = "$0.3.message";
$handle = $rfc822->openfile( $filename,'>' );
print $handle q|Return-Path: <www@list.nl>
Mailing-List: contact list-help@lists.com; run by ezmlm
Precedence: bulk
X-No-Archive: yes
Delivered-To: mailing list list@lists.com
Delivered-To: moderator for list@lists.com
Received: (qmail 24621 invoked from network); 19 Jun 2001 09:40:32 -0000
Date: Tue, 19 Jun 2001 10:59:46 +0200
Message-Id: <200106190859.KAA20385@list.nl>
X-Mailer: Liz::Mail 2.14
X-BulkMailer: Liz/BulkMail 0.26
X-IP: 212.204.145.246 (cm13118-a.maast1.lb.nl.home.com)
MIME-Version: 1.0
From: newsletter@lists.com
To: list@lists.com
Subject: List Synopsis
Content-Type: multipart/alternative; boundary="==Liz::Mail==t0ll9jc2cSwl8Y9"

--==Liz::Mail==t0ll9jc2cSwl8Y9
Content-Type: text/plain
Content-Transfer-Encoding: quoted-printable


--==Liz::Mail==t0ll9jc2cSwl8Y9
Content-Type: text/html
Content-Transfer-Encoding: quoted-printable

<BASE HREF=3D"http://newsletter.lists.com/">
<!-- -----------------------------------------------------------------

   If you can read this, but the rest of the message seems=20
   unintelligible, then you are using an e-mail client that=20
   is not HTML compatible.

----------------------------------------------------------------- -->

<HTML>
<HEAD>
<TITLE>List Synopsis</TITLE>
<STYLE>
<!--B {font-family: Verdana, Arial, Helvetica, sans-serif; font-size: 10pt;=
 font-weight: none; color: black; text-decoration: none; line-height: 1.5;}=
-->
</STYLE>
</HEAD>

<BODY BGCOLOR=3D"#FFFFFF" TEXT=3D"#000000" LINK=3D"#CC3333" VLINK=3D"#CC333=
3" ALINK=3D"#333333">

<DIV align=3D"center">
<TABLE WIDTH=3D"600" BORDER=3D"0" CELLSPACING=3D"0" CELLPADDING=3D"0">
 <TR VALIGN=3D"top" ALIGN=3D"middle">
  <TD COLSPAN=3D"5"><IMG SRC=3D"masthead.jpg" width=3D"600" height=3D"108" =
border=3D"0"></TD>
 </TR>
</TABLE>

<TABLE WIDTH=3D"600" BORDER=3D"0" CELLSPACING=3D"0" CELLPADDING=3D"0">

 <TR>
  <TD WIDTH=3D"5" VALIGN=3D"top" BGCOLOR=3D"#CCCCCC" ROWSPAN=3D"24">
   <FONT SIZE=3D"-5">&nbsp;</FONT>
  </TD>
  <TD WIDTH=3D"114" VALIGN=3D"top" BGCOLOR=3D"#CCCCCC" ROWSPAN=3D"24">
=20=20=20
   <p align=3D"center">
   <i>June&nbsp;19,&nbsp;2001</i>
   </p>

   <br>

   <p class=3D"index">
   <b>Contents:</b><br>
   &nbsp;<A HREF=3D"#user">User Quote</a><br>
   </p>

   <br>

   <div class=3D"quote">
    <i>&quot;Wherever I go in the hotel world, I will always use List - t=
hey put people in my rooms! Their account management team far exceeded my e=
xpectations.  My property was converted quickly and without interruption to=
 our daily operations.&quot;</i>
<br><br>
General Manager<br>Resort hotel, 120 rooms
   </div>
</BODY>
</HTML>
--==Liz::Mail==t0ll9jc2cSwl8Y9--
|;
close( $handle );
ok(-e $filename);
push( @filename,$filename ); #schedule for deletion

# 11 Check if the RFC822 message can be read and produces correct XML
$rfc822->extra_attribute( 'reset');
$document = $rfc822->Document( $filename );
skip($DateParse,$document->xml,q|<document>
<attributes>
<published>20010619085946</published>
<id>t/13rfc822.t.3.message</id>
</attributes>
<text>
<from>newsletter@lists.com</from>
<title>List Synopsis</title>
<to>list@lists.com</to>
List Synopsis 
 

 
 

 

 
 
  
     
  
 

 

  
   
   &#160;
   
   
   
    
   June&#160;19,&#160;2001
    

    

    
   Contents: 
   &#160;User Quote 
    

    

    
    &quot;Wherever I go in the hotel world, I will always use List - they put people in my rooms! Their account management team far exceeded my expectations.  My property was converted quickly and without interruption to our daily operations.&quot;
  
General Manager Resort hotel, 120 rooms
</text>
</document>
|);

# Reset offset and length routines
$offset = $length = 0;
$rfc822->extra_attribute(
 [\$offset,qw(offset number notkey 1)],
 [sub {$length = -s shift; $offset += $length; $length},
  qw(length number notkey 1)],
);

# 12 Create an external file that has HTML parts without text
$filename = "$0.4.message";
$handle = $rfc822->openfile( $filename,'>' );
print $handle q|Return-Path: <me@what.com>
From: whatta@Mail-box.cz
Message-ID: <0000373d7e52$000029fc$0000268a@pop.Atlas.cz>
To: you@what.com
Subject: Niche Markets Are Our Specialty
Date: Fri, 01 Feb 2002 11:07:17 -2000
MIME-Version: 1.0
Content-Type: text/html;
	charset="iso-8859-1"
X-UIDL: j4C!!kJ;!!G:j"!a$A!!

<x-html>
<HTML>
<table border="0" width="100%">
  <tr>
<td width=90%>

<br><br>
      <p align="center"><b><i><font face="Arial,Helvetica,Helvetica" color="darkblue" size="6">
 For 5 Years, Our E-Mail Campaigns Have Produced Staggering Response Rates!</font></i></b></p>

      <p align="center"><br>
      <b><font face="Arial,Helvetica" color="darkred"><big><big>
Responsive General or Targeted, Managed<nobr> "Opt-In" E-Mail Lists</nobr></big></big></font></b>

<BR><BR>
</HTML>

</x-html>
|;
close( $handle );
ok(-e $filename);
push( @filename,$filename ); #schedule for deletion

# 13 Check if the RFC822 message can be read and produces correct XML
$document = $rfc822->Document( $filename );
skip($DateParse,$document->xml,q|<document>
<attributes>
<offset>0</offset>
<length>794</length>
<published>20020202070717</published>
<id>t/13rfc822.t.4.message</id>
</attributes>
<text>
<from>whatta@Mail-box.cz</from>
<title>Niche Markets Are Our Specialty</title>
<to>you@what.com</to>
For 5 Years, Our E-Mail Campaigns Have Produced Staggering Response Rates!   

        
         
Responsive General or Targeted, Managed  "Opt-In" E-Mail Lists
</text>
</document>
|);

# 14 Attempt to create a docseq object out of this
my $docseq = $rfc822->Docseq( @filename );
skip($DateParse,$docseq->xml,q|<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<offset>794</offset>
<length>1154</length>
<published>20011202135713</published>
<id>t/13rfc822.t.1.message</id>
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
<offset>1948</offset>
<length>2069</length>
<published>20010327182610</published>
<id>t/13rfc822.t.2.message</id>
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
<document>
<attributes>
<offset>4017</offset>
<length>2607</length>
<published>20010619085946</published>
<id>t/13rfc822.t.3.message</id>
</attributes>
<text>
<from>newsletter@lists.com</from>
<title>List Synopsis</title>
<to>list@lists.com</to>
List Synopsis 
 

 
 

 

 
 
  
     
  
 

 

  
   
   &#160;
   
   
   
    
   June&#160;19,&#160;2001
    

    

    
   Contents: 
   &#160;User Quote 
    

    

    
    &quot;Wherever I go in the hotel world, I will always use List - they put people in my rooms! Their account management team far exceeded my expectations.  My property was converted quickly and without interruption to our daily operations.&quot;
  
General Manager Resort hotel, 120 rooms
</text>
</document>
<document>
<attributes>
<offset>6624</offset>
<length>794</length>
<published>20020202070717</published>
<id>t/13rfc822.t.4.message</id>
</attributes>
<text>
<from>whatta@Mail-box.cz</from>
<title>Niche Markets Are Our Specialty</title>
<to>you@what.com</to>
For 5 Years, Our E-Mail Campaigns Have Produced Staggering Response Rates!   

        
         
Responsive General or Targeted, Managed  "Opt-In" E-Mail Lists
</text>
</document>
</ntv:docseq>
|);

# 15 Check if we can create a resource object
my $resource = $rfc822->Resource;
ok($resource);

# 16 Check if it has the right XML
$resource->xml unless ok($resource->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
<indexcreation>
<attribute name="id" type="string" key="key-unique" nvals="1"/>
<attribute name="length" type="number" key="notkey" nvals="1"/>
<attribute name="offset" type="number" key="notkey" nvals="1"/>
<attribute name="published" type="number" key="notkey" nvals="1"/>
<texttype name="from"/>
<texttype name="title" weight="1000"/>
<texttype name="to"/>
</indexcreation>
</ntv:resource>
EOD
