use Test;
BEGIN { plan tests => 42 }
END {
  ok(0) unless $loaded;
  system( "rm -rf $temp/*; rmdir $temp" ) if $temp;
  system( "rm -rf $targzdir/*; rmdir $targzdir" ) if $targzdir;
  unlink( @file,$mbox ) if @file;
}

use Cwd qw(cwd);

# 01 Check if we can load the modules
use NexTrieve qw(Docseq Resource RFC822 Targz);
$loaded = 1;
ok(1);

# 02 Check if we can create a NexTrieve object
my $ntv = NexTrieve->new( {
 RaiseError => 1,
} );
ok($ntv);

# 03 Create temporary directory for this run
my $basedir = $0 =~ m#^(.*?/)[^/]+$# ? $1 : '';
$basedir = cwd."/$basedir" unless $basedir =~ s#^\s*(?=/)##; 
$temp = $basedir.'tmp';
mkdir( $temp,0777 );
ok(-d $temp);
$ntv->Tmp( $temp );

# 04 Check if we can create a Targz object
$targzdir = $basedir.'targz';
my $targz = $ntv->Targz( $targzdir );
ok($targz);

# 05 Check if there is a targz directory
ok($targz->directory);

# 06 Check if the targz directory is what we expect
ok($targz->directory eq $targzdir);

# 07 Check if the targz directory exists
ok(-d $targzdir);

# 08 Check if the targz/original directory exists
ok(-d "$targzdir/rfc");

# 09 Check if the targz/xml directory exists
ok(-d "$targzdir/xml");

# 10 Check if there is a work directory
my $work = $targz->work;
ok($work);

# 11 Check if the work directory exists
ok(-d $work);

# 12 Let the object die and see if the work directory is empty
undef( $targz );
ok(!<$work/*>);

# 13 create the files to work with
my @date = split( "\n",
'Date: Fri, 2 May 1997 15:06:29 -0100
Date: Fri, 2 May 1997 15:06:29 -0200
Date: Fri, 2 May 1997 15:06:29 -0300
Date: Fri, 2 May 1997 15:06:29 -0400
Date: Wed, 9 Aug 2000 23:08:26 +0200
Date: Sun, 3 Dec 2000 11:13:01 +1000
Date: Wed, 13 Dec 2000 10:55:33 +0100
' );

my $message = $basedir.'rfc';
$mbox = $basedir.'rfc.mbox';
my $handle = $ntv->openfile( $mbox,'>' );
foreach (1..@date) {
  my $file = "$message.$_";
  push( @file,$file );
  my $text = <<EOD;
From: me
To: you
$date[$_-1]
Subject: Message $_

Text of message $_
EOD
  $ntv->splat( $ntv->openfile( "$message.$_",'>' ),$text );
  print $handle "From me\n",$text;
}
close( $handle );
ok(@{[<$message.?>]} == @file);

# 14 Create a new targz object
$targz = $ntv->Targz( $targzdir );
ok($targz);

# 15 Add the files that we just created
ok($targz->add_file( \@file ));

# 16 Add the files that we just created again
ok($targz->add_file( @file ));

# 17 Obtain the dates that are now available in this targz
ok(join(',',@{$targz->datestamps}) eq '19970502,20000809,20001203,20001213');

# 18 Start over again
system( "rm -rf $targzdir/*" );
ok(!<$targzdir/*>);

# 19 Create an RFC822 object
my $rfc822 = $ntv->RFC822( {
 field2attribute        => [
                            [qw(id id number key-unique 1)],
                            [qw(Date published number notkey 1)],
                           ],
 field2texttype         => [
                            'From',
                            [qw(Subject title 1000)],
                            'To',
                           ],
 attribute_processor    => [
                            [qw(published timestamp)],
                           ],
} );
ok($rfc822);

# 20 Create a streaming Docseq object
my $stream = "$temp/docseq.ntvml";
my $docseq = $ntv->Docseq( {stream => $stream} );
ok($docseq);

# 21 Create a new Targz object
$targz = $ntv->Targz( $targzdir,{Docseq => $docseq, RFC822 => $rfc822} );
ok($targz);

# 22 Add the files that we just created again
ok($targz->add_file( @file ));

# 23 Check the list of ids
ok(join(',',@{$targz->ids}) eq
 '862531201,862531202,862531203,862531204,965779201,975801601,976665601');

# 24 Check a partial list of ids
ok(join(',',@{$targz->ids( 19970502 )}) eq
 '862531201,862531202,862531203,862531204');

# 25 Check another partial list of ids
ok(join(',',@{$targz->ids( '^2' )}) eq '965779201,975801601,976665601');

# 26 Obtain the absolute filename of one of the files
ok($targz->filename( 965779201 ) eq "$temp/Targz/$$/20000809/965779201");

# 27 Obtain the absolute filename of another of the files
ok($targz->filename( "862531204.xml" ) eq
 "$temp/Targz/$$/19970502.xml/862531204.xml");

# 28 Add the files that we just created again, but have them removed now
$targz->rm_original( 1 );
ok($targz->add_file( @file ));

# 29 Check the number of files
ok($targz->count == 14);

# 30 See if the original files are gone
ok(!@{[<$message.?>]});

# 31 Check if the docseq is what we expect it to be
$docseq->done;
my $docseqxml = $ntv->slurp( $ntv->openfile( $stream ) );
warn $docseqxml unless ok($docseqxml,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<published>19970502160629</published>
<id>862531201</id>
</attributes>
<text>
<from>me</from>
<title>Message 1</title>
<to>you</to>
Text of message 1
</text>
</document>
<document>
<attributes>
<published>19970502170629</published>
<id>862531202</id>
</attributes>
<text>
<from>me</from>
<title>Message 2</title>
<to>you</to>
Text of message 2
</text>
</document>
<document>
<attributes>
<published>19970502180629</published>
<id>862531203</id>
</attributes>
<text>
<from>me</from>
<title>Message 3</title>
<to>you</to>
Text of message 3
</text>
</document>
<document>
<attributes>
<published>19970502190629</published>
<id>862531204</id>
</attributes>
<text>
<from>me</from>
<title>Message 4</title>
<to>you</to>
Text of message 4
</text>
</document>
<document>
<attributes>
<published>20000809210826</published>
<id>965779201</id>
</attributes>
<text>
<from>me</from>
<title>Message 5</title>
<to>you</to>
Text of message 5
</text>
</document>
<document>
<attributes>
<published>20001203011301</published>
<id>975801601</id>
</attributes>
<text>
<from>me</from>
<title>Message 6</title>
<to>you</to>
Text of message 6
</text>
</document>
<document>
<attributes>
<published>20001213095533</published>
<id>976665601</id>
</attributes>
<text>
<from>me</from>
<title>Message 7</title>
<to>you</to>
Text of message 7
</text>
</document>
<document>
<attributes>
<published>19970502160629</published>
<id>862531201</id>
</attributes>
<text>
<from>me</from>
<title>Message 1</title>
<to>you</to>
Text of message 1
</text>
</document>
<document>
<attributes>
<published>19970502170629</published>
<id>862531202</id>
</attributes>
<text>
<from>me</from>
<title>Message 2</title>
<to>you</to>
Text of message 2
</text>
</document>
<document>
<attributes>
<published>19970502180629</published>
<id>862531203</id>
</attributes>
<text>
<from>me</from>
<title>Message 3</title>
<to>you</to>
Text of message 3
</text>
</document>
<document>
<attributes>
<published>19970502190629</published>
<id>862531204</id>
</attributes>
<text>
<from>me</from>
<title>Message 4</title>
<to>you</to>
Text of message 4
</text>
</document>
<document>
<attributes>
<published>19970502160629</published>
<id>862531205</id>
</attributes>
<text>
<from>me</from>
<title>Message 1</title>
<to>you</to>
Text of message 1
</text>
</document>
<document>
<attributes>
<published>19970502170629</published>
<id>862531206</id>
</attributes>
<text>
<from>me</from>
<title>Message 2</title>
<to>you</to>
Text of message 2
</text>
</document>
<document>
<attributes>
<published>19970502180629</published>
<id>862531207</id>
</attributes>
<text>
<from>me</from>
<title>Message 3</title>
<to>you</to>
Text of message 3
</text>
</document>
<document>
<attributes>
<published>19970502190629</published>
<id>862531208</id>
</attributes>
<text>
<from>me</from>
<title>Message 4</title>
<to>you</to>
Text of message 4
</text>
</document>
<document>
<attributes>
<published>20000809210826</published>
<id>965779201</id>
</attributes>
<text>
<from>me</from>
<title>Message 5</title>
<to>you</to>
Text of message 5
</text>
</document>
<document>
<attributes>
<published>20000809210826</published>
<id>965779202</id>
</attributes>
<text>
<from>me</from>
<title>Message 5</title>
<to>you</to>
Text of message 5
</text>
</document>
<document>
<attributes>
<published>20001203011301</published>
<id>975801601</id>
</attributes>
<text>
<from>me</from>
<title>Message 6</title>
<to>you</to>
Text of message 6
</text>
</document>
<document>
<attributes>
<published>20001203011301</published>
<id>975801602</id>
</attributes>
<text>
<from>me</from>
<title>Message 6</title>
<to>you</to>
Text of message 6
</text>
</document>
<document>
<attributes>
<published>20001213095533</published>
<id>976665601</id>
</attributes>
<text>
<from>me</from>
<title>Message 7</title>
<to>you</to>
Text of message 7
</text>
</document>
<document>
<attributes>
<published>20001213095533</published>
<id>976665602</id>
</attributes>
<text>
<from>me</from>
<title>Message 7</title>
<to>you</to>
Text of message 7
</text>
</document>
</ntv:docseq>
EOD

# 32 Create a new docseq object and remake the XML
ok($targz->update_xml( '',$ntv->Docseq( {stream => $stream} ) ) == 14);

# 33 Check if the XML is what we expect it to be
$docseqxml = $ntv->slurp( $ntv->openfile( $stream ) );
my $okdocseqxml = <<EOD;
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<published>19970502160629</published>
<id>862531201</id>
</attributes>
<text>
<from>me</from>
<title>Message 1</title>
<to>you</to>
Text of message 1
</text>
</document>
<document>
<attributes>
<published>19970502170629</published>
<id>862531202</id>
</attributes>
<text>
<from>me</from>
<title>Message 2</title>
<to>you</to>
Text of message 2
</text>
</document>
<document>
<attributes>
<published>19970502180629</published>
<id>862531203</id>
</attributes>
<text>
<from>me</from>
<title>Message 3</title>
<to>you</to>
Text of message 3
</text>
</document>
<document>
<attributes>
<published>19970502190629</published>
<id>862531204</id>
</attributes>
<text>
<from>me</from>
<title>Message 4</title>
<to>you</to>
Text of message 4
</text>
</document>
<document>
<attributes>
<published>19970502160629</published>
<id>862531205</id>
</attributes>
<text>
<from>me</from>
<title>Message 1</title>
<to>you</to>
Text of message 1
</text>
</document>
<document>
<attributes>
<published>19970502170629</published>
<id>862531206</id>
</attributes>
<text>
<from>me</from>
<title>Message 2</title>
<to>you</to>
Text of message 2
</text>
</document>
<document>
<attributes>
<published>19970502180629</published>
<id>862531207</id>
</attributes>
<text>
<from>me</from>
<title>Message 3</title>
<to>you</to>
Text of message 3
</text>
</document>
<document>
<attributes>
<published>19970502190629</published>
<id>862531208</id>
</attributes>
<text>
<from>me</from>
<title>Message 4</title>
<to>you</to>
Text of message 4
</text>
</document>
<document>
<attributes>
<published>20000809210826</published>
<id>965779201</id>
</attributes>
<text>
<from>me</from>
<title>Message 5</title>
<to>you</to>
Text of message 5
</text>
</document>
<document>
<attributes>
<published>20000809210826</published>
<id>965779202</id>
</attributes>
<text>
<from>me</from>
<title>Message 5</title>
<to>you</to>
Text of message 5
</text>
</document>
<document>
<attributes>
<published>20001203011301</published>
<id>975801601</id>
</attributes>
<text>
<from>me</from>
<title>Message 6</title>
<to>you</to>
Text of message 6
</text>
</document>
<document>
<attributes>
<published>20001203011301</published>
<id>975801602</id>
</attributes>
<text>
<from>me</from>
<title>Message 6</title>
<to>you</to>
Text of message 6
</text>
</document>
<document>
<attributes>
<published>20001213095533</published>
<id>976665601</id>
</attributes>
<text>
<from>me</from>
<title>Message 7</title>
<to>you</to>
Text of message 7
</text>
</document>
<document>
<attributes>
<published>20001213095533</published>
<id>976665602</id>
</attributes>
<text>
<from>me</from>
<title>Message 7</title>
<to>you</to>
Text of message 7
</text>
</document>
</ntv:docseq>
EOD
warn $docseqxml unless ok($docseqxml,$okdocseqxml);

# 34 Check if there is an old XML directory now
ok(-d "$targzdir/xml.old");

# 35 Attempt to create document sequence XML from the tar-files
$docseqxml = $targz->xml;
warn $docseqxml unless ok($docseqxml,$okdocseqxml);

# 36 Attempt to create document sequence stream from the tar-files
unlink( $stream );
$targz->xml( $ntv->Docseq( {stream => $stream} ) );
$docseqxml = $ntv->slurp( $ntv->openfile( $stream ) );
warn $docseqxml unless ok($docseqxml,$okdocseqxml);

# 37 Start over again
system( "rm -rf $targzdir/*" );
ok(!<$targzdir/*>);

# 38 Create a new Targz object for doing the mbox
unlink( $stream );
$targz = $ntv->Targz( $targzdir,{
 Docseq => $ntv->Docseq( {stream => $stream} ),
 RFC822 => $rfc822,
} );
ok($targz);

# 39 Create a targz from the mbox
ok($targz->add_mbox( $mbox ));

# 40 Check if we can create a resource file
my $resource = $targz->Resource;
ok($resource);

# 41 Check if it has the right XML
$resource->xml unless ok($resource->xml,<<EOD);
<?xml version="1.0" encoding="iso-8859-1"?>
<ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
<indexcreation>
<attribute name="id" type="number" key="key-unique" nvals="1"/>
<attribute name="published" type="number" key="notkey" nvals="1"/>
<texttype name="from"/>
<texttype name="title" weight="1000"/>
<texttype name="to"/>
</indexcreation>
</ntv:resource>
EOD

# 42 Check if the docseq is what we expect it to be
undef( $targz );
$docseqxml = $ntv->slurp( $ntv->openfile( $stream ) );
warn $docseqxml unless ok($docseqxml,<<EOD);
<?xml version="1.0" encoding="utf-8"?>
<ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
<document>
<attributes>
<published>19970502160629</published>
<id>862531201</id>
</attributes>
<text>
<from>me</from>
<title>Message 1</title>
<to>you</to>
Text of message 1
</text>
</document>
<document>
<attributes>
<published>19970502170629</published>
<id>862531202</id>
</attributes>
<text>
<from>me</from>
<title>Message 2</title>
<to>you</to>
Text of message 2
</text>
</document>
<document>
<attributes>
<published>19970502180629</published>
<id>862531203</id>
</attributes>
<text>
<from>me</from>
<title>Message 3</title>
<to>you</to>
Text of message 3
</text>
</document>
<document>
<attributes>
<published>19970502190629</published>
<id>862531204</id>
</attributes>
<text>
<from>me</from>
<title>Message 4</title>
<to>you</to>
Text of message 4
</text>
</document>
<document>
<attributes>
<published>20000809210826</published>
<id>965779201</id>
</attributes>
<text>
<from>me</from>
<title>Message 5</title>
<to>you</to>
Text of message 5
</text>
</document>
<document>
<attributes>
<published>20001203011301</published>
<id>975801601</id>
</attributes>
<text>
<from>me</from>
<title>Message 6</title>
<to>you</to>
Text of message 6
</text>
</document>
<document>
<attributes>
<published>20001213095533</published>
<id>976665601</id>
</attributes>
<text>
<from>me</from>
<title>Message 7</title>
<to>you</to>
Text of message 7
</text>
</document>
</ntv:docseq>
EOD
