use Test;
BEGIN { plan tests => 20 }
END {
  ok(0) unless $loaded;
  unlink( @filename ) if @filename;
}

use NexTrieve qw(HTML Resource);
$loaded = 1;
ok( 1 );

eval( 'use Date::Parse ()' );
my $DateParse = defined( $Date::Parse::VERSION ) ?
 '' : "Module Date::Parse not installed";

my $ntv = NexTrieve->new( {RaiseError => 1} );
my $version = $ntv->version;

# 02 Create empty HTML object
my $html = $ntv->HTML->htmlsimple;
ok($html);

# 03 Create a simple document from an HTML stream
$document = $html->Document( <<EOD );
<html>
<head>
<title>This is the title</title>
</head>
<body>
This is the body
</body>
</html>
EOD
$document->xml unless ok($document->xml,<<EOD );
<document>
<attributes>
<title>This is the title</title>
</attributes>
<text>
<title>This is the title</title>
This is the body
</text>
</document>
EOD

# 04 Create an external file that is slightly more complicated
my $filename = "$0.1.html";
my $handle = $html->openfile( $filename,'>' );
print $handle <<EOD;
<html>
<head>
<title>This is the title of 1</title>
<meta http-equiv="Content-type" content="text/html; charset=ISO-8859-1">
<meta name="description" content="Description of 1">
<meta name="keywords" content="Keywords of 1">
</head>
<body>
�l�ve
This is the body of 1
</body>
</html>
EOD
close( $handle );
ok(-e $filename);
push( @filename,$filename ); #schedule for deletion

# 05 Check if the HTML can be read and produces correct XML
$document = $html->Document( $filename );
$document->xml unless ok($document->xml,<<EOD);
<document>
<attributes>
<filename>$filename</filename>
<title>This is the title of 1</title>
</attributes>
<text>
<description>Description of 1</description>
<keywords>Keywords of 1</keywords>
<title>This is the title of 1</title>
�l�ve
This is the body of 1
</text>
</document>
EOD

# 06 Check if the encoding of the document is correct
ok($document->encoding,'iso-8859-1');

# 07 Create an external file that is pretty bad HTML-wise
$filename = "$0.2.html";
$handle = $html->openfile( $filename,'>' );
print $handle <<EOD;
<!-- HTML comment -->
<script>this is a script that should not appear</script>
<title>This is the title of 2</title>
<meta http-equiv="Content-type" content="text/html; charset=UTF-8">
<meta name="description" content="Description of 2">
<meta name="keywords" content="Keywords of 2">
élève
This is the body of 2
EOD
close( $handle );
ok(-e $filename);
push( @filename,$filename ); #schedule for deletion

# 08 Check if the HTML can be read and produces correct XML
$document = $html->Document( $filename );
$document->xml unless ok($document->xml,<<EOD);
<document>
<attributes>
<filename>$filename</filename>
<title>This is the title of 2</title>
</attributes>
<text>
<description>Description of 2</description>
<keywords>Keywords of 2</keywords>
<title>This is the title of 2</title>
élève
This is the body of 2
</text>
</document>
EOD

# 09 Check if the encoding of the document is correct
ok($document->encoding,'utf-8');

# 10 Check whether &#150 works ok
$document = $html->Document( <<EOD );
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML4.0//EN" "http://www.w3.org/TR/REC/-html40/strict.dtd">
uiteraard veel standards uit de periode 1920&1501950, maar daarnaast blues
dixielandorkesten, jazzcombo's, big bands, blues&#150 en popgroepen
(op onder meer jazzfestivals, de Zeeuwse Jazzdag, in caf&#233s en restaurants,
priv&#233&3150feesten en voor Omroep Zeeland) bewijst wellicht, dat REMAKE
is HANS VAN DE VELDE &#150 trompet, fl&#252gelhorn, bluesharp, zang; MARIJKE
POPPE &#150 sopraansax, altsax, tenorsax, zang; PIERRE DE NIJS &#150 gitaar,
zang; LEO VAN DER TOORN &#150 contrabas, basgitaar; GERRIT KOOGER &#150 drums.
EOD
$document->xml unless ok($document->xml,<<EOD);
<document>
<text>
uiteraard veel standards uit de periode 1920&amp;1501950, maar daarnaast blues
dixielandorkesten, jazzcombo's, big bands, blues&amp;#150 en popgroepen
(op onder meer jazzfestivals, de Zeeuwse Jazzdag, in caf&#233;s en restaurants,
priv&#233;&amp;3150feesten en voor Omroep Zeeland) bewijst wellicht, dat REMAKE
is HANS VAN DE VELDE &amp;#150 trompet, fl&#252;gelhorn, bluesharp, zang; MARIJKE
POPPE &amp;#150 sopraansax, altsax, tenorsax, zang; PIERRE DE NIJS &amp;#150 gitaar,
zang; LEO VAN DER TOORN &amp;#150 contrabas, basgitaar; GERRIT KOOGER &amp;#150 drums.
</text>
</document>
EOD

# 11 Attempt to create a docseq object out of this
$ntv->DefaultInputEncoding( 'ISO-8859-1' );
my $docseq = $html->Docseq( @filename );
$docseq->done;
$docseq->xml unless ok($docseq->xml,my $xml = <<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<filename>t/12html.t.1.html</filename>
<title>This is the title of 1</title>
</attributes>
<text>
<description>Description of 1</description>
<keywords>Keywords of 1</keywords>
<title>This is the title of 1</title>
élève
This is the body of 1
</text>
</document>
<document>
<attributes>
<filename>t/12html.t.2.html</filename>
<title>This is the title of 2</title>
</attributes>
<text>
<description>Description of 2</description>
<keywords>Keywords of 2</keywords>
<title>This is the title of 2</title>
élève
This is the body of 2
</text>
</document>
</ntv:docseq>
EOD

# 12 Add some extra stuff and check if we can create a resource file
$html->extra_attribute( 
 [\$html,qw(url string notkey 1)],
);
$html->extra_texttype( 
 [\$html,'url',100],
);
my $resource = $html->Resource;
ok($resource);

# 13 Check if it has the right XML
$resource->xml unless ok($resource->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
<indexcreation>
<attribute name="filename" type="string" key="key-unique" nvals="1"/>
<attribute name="title" type="string" key="notkey" nvals="1"/>
<attribute name="url" type="string" key="notkey" nvals="1"/>
<texttype name="description"/>
<texttype name="keywords"/>
<texttype name="title"/>
<texttype name="url" weight="100"/>
</indexcreation>
</ntv:resource>
EOD

# 14 Create a new HTML object for checking MHonArc functionality
$html = $ntv->HTML->mhonarc;
ok($html);

# 15 Create a document from an example message from the MHonArc list itself
$document = $html->Document( q|<!--X-Subject: [loewis@informatik.hu&#45;berlin.de: Bug#131512: Need UTF&#45;8 archives] -->
<!--X-From: Jeff Breidenbach <jeff@jab.org> -->
<!--X-Date: Fri, 01 Feb 2002 13:28:57 &#45;0800 -->
<!--X-Message-Id: E16WlEv&#45;0004PU&#45;00@zamboni.jab.org -->
<!--X-ContentType: text/plain -->
<!--X-Head-End-->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML//EN">
<HTML>
<HEAD>
<TITLE>[loewis@informatik.hu-berlin.de: Bug#131512: Need UTF-8 archives]</TITLE>
<LINK REV="made" HREF="mailto:jeff@jab.org">
</HEAD>
<BODY>
<!--X-Body-Begin-->
<!--X-User-Header-->
<!--X-User-Header-End-->
<!--X-TopPNI-->
<HR>
[Date Prev][<A HREF="msg00001.html">Date Next</A>] [Thread Prev][<A HREF="msg00006.html">Thread Next</A>] [<A HREF="index.html#00000">Date Index</A>][<A HREF="threads.html#00000">Thread Index</A>][<A HREF="../">Top&Search</A>][<A HREF="/cgi-bin/extract-mbox/mhonarc/2002-02?E16WlEv%2D0004PU%2D00%40zamboni%2Ejab%2Eorg">Original</A>]
<HR>

<!--X-TopPNI-End-->
<!--X-MsgBody-->
<!--X-Subject-Header-Begin-->
<H1>[loewis@informatik.hu-berlin.de: Bug#131512: Need UTF-8 archives]</H1>
<HR>
<!--X-Subject-Header-End-->
<UL>
<LI><b>From</b>: Jeff Breidenbach &lt;<A HREF="mailto:jeff@jab.org">jeff@jab.org</A>&gt;</LI>
<LI><b>To</b>: <A HREF="mailto:mhonarc@ncsa.uiuc.edu">mhonarc@ncsa.uiuc.edu</A></LI>
<LI><b>CC</b>: <A HREF="mailto:131512@bugs.debian.org">131512@bugs.debian.org</A>, <A HREF="mailto:loewis@informatik.hu-berlin.de">loewis@informatik.hu-berlin.de</A></LI>
<LI><b>Date</b>: Fri, 01 Feb 2002 13:28:57 -0800</LI>
<LI><b>Message-Id</b>: &lt;<A HREF="msg00000.html">E16WlEv-0004PU-00@zamboni.jab.org</A>&gt;</LI>
</UL>
<!--X-Head-Body-Sep-Begin-->
<HR>
<!--X-Head-Body-Sep-End-->
<!--X-Body-of-Message-->
<PRE>

I received a UTF-8 feature request/patch [1] for MHonARC from a a Debian
GNU/Linux user. Any comments? Is this something that MHonArc might
consider incorporating directly?

Cheers,
Jeff

1. <A HREF="http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=131512">http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=131512</A>&amp;repeatmerged=yes

</PRE>
<!--X-MsgBody-End-->
<!--X-Follow-Ups-->
<HR>
<DL><DT><B>Follow-Ups from:</B>
<DD>
<A HREF="msg00006.html">Earl Hood &lt;ehood@hydra.acs.uci.edu&gt;</A><BR>
</DL>
<!--X-Follow-Ups-End-->
<!--X-References-->
<!--X-References-End-->
<!--X-BotPNI-->
<HR>
[Date Prev][<A HREF="msg00001.html">Date Next</A>] [Thread Prev][<A HREF="msg00006.html">Thread Next</A>] [<A HREF="index.html#00000">Date Index</A>][<A HREF="threads.html#00000">Thread Index</A>][<A HREF="../">Top&Search</A>][<A HREF="/cgi-bin/extract-mbox/mhonarc/2002-02?E16WlEv%2D0004PU%2D00%40zamboni%2Ejab%2Eorg">Original</A>]
<HR>

<!--X-BotPNI-End-->
<!--X-User-Footer-->
<!--X-User-Footer-End-->
</BODY>
</HTML>
| );
skip($DateParse,$document->xml,q|<document>
<attributes>
<date>20020201</date>
<from>Jeff Breidenbach &lt;jeff@jab.org&gt;</from>
<subject>[loewis@informatik.hu-berlin.de: Bug#131512: Need UTF-8 archives]</subject>
</attributes>
<text>
<subject>[loewis@informatik.hu-berlin.de: Bug#131512: Need UTF-8 archives]</subject>
I received a UTF-8 feature request/patch [1] for MHonARC from a a Debian
GNU/Linux user. Any comments? Is this something that MHonArc might
consider incorporating directly?

Cheers,
Jeff

1. http://bugs.debian.org/cgi-bin/bugreport.cgi?bug=131512&amp;repeatmerged=yes
</text>
</document>
|);

# 16 Attempt to create a document from a URL
$html->Set( {RaiseError => 0,PrintError => 1} );
$document = $html->Document( 'www.nextrieve.com/url_fetch_HTML.html','url' );
ok($document);

# 17 Create a new HTML object for checking simple HTML
$html = $ntv->HTML->htmlsimple;
ok($html);

# 18 Check the <P> and & in a title case
$document = $html->Document( <<EOD,'' );
<TITLE>
Supporting Software & Reuse Within an
Integrated Software Development Environment
 (Position Paper)
 <P>
 </TITLE>
EOD
$document->xml unless ok($document->xml,<<EOD);
<document>
<attributes>
<title>
Supporting Software &amp; Reuse Within an
Integrated Software Development Environment
 (Position Paper)
  
 </title>
</attributes>
<text>
<title>
Supporting Software &amp; Reuse Within an
Integrated Software Development Environment
 (Position Paper)
  
 </title>
</text>
</document>
EOD

# 19 Check the ASP-style tags
$html->asp;
$document = $html->Document( <<EOD,'' );
Before
<% echo ("You may use ASP-style tags"); %>
After
EOD
$document->xml unless ok($document->xml,<<EOD);
<document>
<text>
Before

After
</text>
</document>
EOD

# 20 Check the PHP-style tags
$html->php;
$document = $html->Document( <<EOD,'' );
1.  <? echo ("this is the simplest, an SGML processing instruction\n"); ?>
    <?= expression ?> This is a shortcut for "<? echo expression ?>"
    
2.  <?php echo("if you want to serve XHTML/XML documents, do like this\n"); ?>

3.  <script language="php">
        echo ("some editors (like FrontPage) don't
              like processing instructions");
    </script>

4.  <% echo ("You may optionally use ASP-style tags"); %>
    <%= \$variable; # This is a shortcut for "<% echo . . ." %>

EOD
$document->xml unless ok($document->xml,<<EOD);
<document>
<text>
1.  
     This is a shortcut for ""
    
2.  

3.  

4.
</text>
</document>
EOD
