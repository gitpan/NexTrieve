package NexTrieve::Overview;

# Make sure we do everything by the book
# Set version information

use strict;
$NexTrieve::Overview::VERSION = '0.33';

# Show warning that you shouldn't -use- this module

BEGIN {
  warn <<EOD;
The NexTrieve::Overview module is a documentation module only.  It does not
contain any executable parts and is only made available as a module so that
it can be easily included in a package with its documentation.
EOD
}

# Return false value so that it won't be used by anybody

0;

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Overview - an overview of NexTrieve and its Perl support

=head1 INTRODUCTION

The NexTrieve software was originally developed in 1995 by Kim Hendrikse.  The
initial implementation consisted of a fuzzy-only search engine which became
available to the market in 1995.  As such, it was used by many websites in that
period, most notably for searching mailinglist and corporate websites, some
of which use the original software version to this very day.

During 1999 it became clear that an exact search component was needed for
NexTrieve to be able to stay competitive with other search engine software
out there and an initial implementation of "exact searching" was commenced
by Kim Hendrikse.

In the second half of 2000 a significant financial investment made it possible
to further develop NexTrieve.  Kim's long time friend and fellow student
Gordon Clare joined the team in September 2002.  In the period until 2002 the
following issues with NexTrieve were addressed:

 - exact word search (must have word, may have word, must not have word)
 - fuzzy pattern search with exact "assist"
 - full unicode support rather than just us-ascii
 - XML input and output of all aspects of NexTrieve
 - scalability: gigabytes of content can be indexed on normal PC hardware
 - scalability: load balancing caching query server
 - filters for indexing email and HTML

In the beginning of 2002, the new incarnation of NexTrieve had matured enough
to be released to the general public.  To introduce NexTrieve to the Perl
community, it was decided that there should be full support for all aspects
of NexTrieve in Perl.  And thus the family of NexTrieve::xxx Perl modules
was developed by Elizabeth Mattijsen, a long-time user of the NexTrieve
search engine software.

=head1 ASPECTS OF NEXTRIEVE COVERED

The NexTrieve Perl modules perform the following tasks using a Perl object
oriented interface:

 - creation and maintenance of NexTrieve collections
 - creation and maintenance of NexTrieve resource-files
 - completely customizable conversion of HTML-files to NTVML (NexTrieve XML)
 - completely customizable conversion of PDF-files to NTVML (NexTrieve XML)
 - completely customizable conversion of email/mailboxes to NTVML
 - completely customizable conversion of DBI statement handles  to NTVML
 - handling conversions from iso-8859-* and windows-125* to UTF-8 internally
 - using external conversion tools such as iconv for other encoding conversions
 - indexing of NTVML using "ntvindex" program, creating a NexTrieve index
 - checking the integrity of a NexTrieve index using the "ntvcheck" program
 - optimizing a NexTrieve index using the "ntvopt" program
 - creating the NexTrieve query XML
 - searching a NexTrieve index using the "ntvsearch" program
 - starting a NexTrieve server process using the "ntvsearchd" program
 - searching a NexTrieve index using a NexTrieve server process
 - updating an index while keeping current NexTrieve server running
 - checking whether a NexTrieve server is running
 - stopping a NexTrieve server process
 - checking the integrity of a NexTrieve index
 - checking the query log of a NexTrieve server for queries
 - replaying the queries of a query log against an index
 - providing hooks and handles for third-party development of additional modules

The following aspects of the NexTrieve search engine software are not (yet)
handled:

 - some aspects of NexTrieve Collections
 - <ultralite> section in NexTrieve resource-file
 - Caching Query Server configuration file
 - fetching and updating of NexTrieve licenses

=head1 CREATING AN INDEX

Before a NexTrieve search engine service can be created, the content that needs
to be searched must be indexed by NexTrieve into a so-called "NexTrieve index",
usually just referred to as an "index".

Because NexTrieve only understands XML on input, any source of content that is
not XML first needs to be converted to a so-called "NexTrieve document
sequence", usually referred to as a "document sequence" or even as a "docseq".

=head2 But what is XML?

For those of you who do not know what XML is: well, it's short for
"eXtensible Markup Language".  For those of you who know what HTML is: it's
a sort of HTML in which you make up the names of the tags yourself.  The
main important things about XML is, is that tags, usually referred to as
"containers", are B<always> strictly started and finished.  So, a sequence
such as

 <ul>
  <li>choice 1
  <li>choice 2
 </ul>

would not be legal XML because the <li> containers are not "finished".  The
proper way to do this, would be:

 <ul>
  <li>choice 1</li>
  <li>choice 2</li>
 </ul>

You should also note that all containers should be finished in their own
scope.  Therefore a sequence such as:

 <b><i>bold and italic</b></i>

would not be legal because the <b> is finished before the <i>, which was
started after the <b>, is finished.  The proper way to do this would be:

 <b><i>bold and italic</i></b>

The XML standard is not strict about a lot of things, but it is B<very>
strict about opening and closing tags.

Sometimes a container is empty, e.g. in HTML:

 <br>

which would be illegal in XML because the container <br> is opened, but not
closed.  There are two proper ways of handling this in XML:

 <br></br>

or:

 <br/>

You will see examples of this in the rest of this document.

So, this should get you up to speed with at least some aspects of XML so that
it hopefully is not all abracadabra what is going to follow next.

=head2 The NexTrieve document

Getting back to the "document sequence": a document sequence consists of a
number of "NexTrieve documents" or just "documents", each of which is a
self-contained piece of XML.  The basic format of a document is:

 <document>
  <attributes>
  :
  : (attributes associated with this document)
  :
  </attributes>
  <text>
  :
  : (text associated with this document)
  :
  </text>
 </document>

The attributes of a document specify the meta-information of a document.
Attributes can be informational only (e.g. the filename of the source of the
document) or they can be useful as a constraint during searching (e.g. the
last-modified date of the source of the document, which would allow a search
limited to documents that have been changed since or before a certain date).
An example of a "filename" and a "date" attribute would be:

 <attributes>
  <filename>/directory/filename.ext</filename>
  <date>20020309</date>
 </attributes>

The text of a document specifies which part(s) of the source of the document
should be available for searching.  This can just be a piece of text by
itself.  Or it can contain fields inside the text that indicate a specific
type of text, usually referred to as "text types".  Examples of text types
would be "title", "summary" or "header".  During the NexTrieve search process,
different weights can be assigned to text found in a particular text type.
This e.g. allows text found in the "title" of a document to be considered
much more important than text found in the rest of a document.  An example of
a "title" text type would be:

 <text>
  <title>This is the title of the document</title>
  This is the text of the document.
 </text>

=head2 The NexTrieve resource file

The developer using NexTrieve is completely free in the definition and naming
of attributes and text types of which a document is supposed to consist.
Exactly which attributes and text types should be expected by the NexTrieve
indexing program, is determined by the so-called "NexTrieve resource file" or
just "resource file".  Apart from attributes and text type definitions, the
resource file also stores other aspects of the NexTrieve indexing and
searching process, such as the location of the index directory.  A well
defined resource file is therefore the only parameter that is needed for the
successful indexing and searching of a specific set of documents.

An example of a resource file would be:

 <ntv:resource xmlns:ntv="http://www.nextrieve.com/1.0">
  <indexdir name="/directory/index"/>
  <indexcreation>
   <attribute name="filename" type="string" key="key-unique"/>
   <attribute name="date" type="number"/>
   <texttype name="title"/>
  </indexcreation>
 </ntv:resource>

=head2 The NexTrieve document sequence

The document sequence is nothing but an XML container around a number of
documents.  An example of a document sequence would be:

 <ntv:docseq xmlns:ntv="http://www.nextrieve.com/1.0">
  <document>
   :
  </document>
  <document>
   :
  </document>
 </ntv:docseq>

The naming of the outer XML container is a little more complex than that of
the XML container of the document because of various XML-related reasons,
none of which are important at this stage.  Suffice to say that because there
is version information in there (the "1.0"), it is guaranteed that an upgrade
path is available for future versions of potentially incompatible XML.

So, getting back to the indexing process: when the NexTrieve indexing program
"ntvindex" indexes a document sequence, it creates an representation of the
documents indexed in a directory.  That directory contains a number of files,
all with the .ntv extension, that comprise the NexTrieve index.  The
directory in which these files are stored, is generally referred to as the
"NexTrieve index directory" or "index directory".  Or even shorter, as the
"indexdir".

=head2 Incremental indexing

There is no difference between an indexing process from scratch (where all
documents that are supposed to be searchable are part of the document
sequence being indexed) or an incremental indexing process (where only the
"new" and "changed" documents are part of a document sequence) other than
the selection of the documents that are part of the document sequence.  In
the first case, the index directory is empty.  In the latter case, the index
directory still contains the files that were the result of one or more
earlier indexing processes.

=head2 Filters

Although many sources of content are becoming more and more XML oriented,
most of today's content is not XML at all.  So, to be able to search non-XML
content, it first needs to be converted to NexTrieve documents and document
sequences, before they can be indexed and consequently searched.

The programs that do this are generally referred to as "NexTrieve filters"
or just "filters".  The NexTrieve package itself contains a number of filters
that convert email boxes, PDF-files and HTML-pages to XML.  The NexTrieve Perl
modules contain some more filters, most notably the capability of converting
content stored in a relational database to a NexTrieve document sequence.

=head2 Is the document sequence a real file?

That is up to the developer.  The NexTrieve indexing program "ntvindex" is
capable of indexing document sequences that are presented to it on "standard
input" or a "pipe".  It is therefore possible to generate a document sequence
"on the fly" and feed that to "ntvindex" without first saving the document
sequence in a file.  It is however recommended to keep a copy of the document
sequence around: it can be a significant help in trying to find the solution
to a problem in a filter, specifically if you are developing your own filter.

=head1 SEARCHING THE INDEX

Once a NexTrieve index has been created or updated, it can be searched by
the NexTrieve searching program, which comes in two flavours: "on demand"
and "at your service".

=head2 On demand searching

When the "on demand" mode of searching is used with NexTrieve, with the
"ntvsearch" program, the files of the index directory are readi from disk
B<each time> a search query is requested.  The advantage of this mode of
operation is that if no search queries are done, no resources of the server
are being used at all.  This disadvantage is of course that each search
query has to go through the same index directory file reading over and
over again.  Even in today's operating systems that optimize disk reading
by buffering the most recently read information, this can become a problem.

So, the "on demand" searching mode of NexTrieve is only recommended to be
used with low traffic search services, typically with search query requests
happening less than once per minute.

=head2 At your service searching

When the "at your service" mode of searching is used with NexTrieve, the
NexTrieve search program "ntvsearchd" is started once, after a (re-)indexing
has been completed.  It then remains in memory, waiting for search query
requests on a "port" (just like a webserver is generally waiting for requests
on port "80").  The disadvantage of this approach is that the server program
consumes valuable computer resources even when it is doing nothing.  But it
has the advantage of being immediately available for performing search
queries, just as a webserver does.  And it has the advantage of keeping
(parts of the) index in memory for quick access.  And it has the advantage
of being able to handle multiple requests simultaneously.

The "at your service" searching mode is typically recommended to be used
with higher traffic search services, typically with search query resquests
happening more than once per minute.

=head2 Search query XML

Like all aspects of NexTrieve, specifying a query is also done using XML.
This is generally referred to as the "NexTrieve query" or just as the
"query".  A typical example of a query request would be:

 <ntv:query xmlns:ntv="http://www.nextrieve.com/1.0">
  <constraint>date &lt; 20020101</constraint>
  <texttype name="title" weight="200"/>
  find me stuff about zippo's
 </ntv:query>

This example constrains the search to documents that have been modified
before January 1st, 2002.  And any text found in the "title" text type
should be considerd twice as important as any text found anywhere else
in a document.

It doesn't matter whether a search query is performed on a "on demand"
search service, or on a "at your service" search service.  The result,
when using the same index, will be identical.

=head2 Search result XML

Of course, the result of a search query is also returned in XML form.
This XML is generally referred to as the "NexTrieve hitlist" or just as
the "hitlist".  A typical example of a hitlist would be:

 <ntv:hitlist xmlns:ntv="http://www.nextrieve.com/1.0">
  <header firsthit="1">
   <warning>"stuff" was not found in the dictionary</warning>
  </header>
  <hit>
   <attributes>
    <filename>/directory/filename.ext</filename>
    <date>20020309</date>
   </attributes>
   <preview>the best thing <b>about</b> <b>zippo</b>'s is that</preview>
  </hit>
  <hit>
  :
  </hit>
 </ntv:hitlist>

The attributes associated with a document are also returned in the hitlist,
allowing any search service to obtain additional information about the
document and/or to obtain the original source of the document before it
was converted to a NexTrieve document by a filter.

A preview, the part of the document most likely to match the search request,
is also returned in the hitlist.  Words that are part of your search query
(in the case of an exact word search query) will be highlighted in the
preview using the <b> container.  If a fuzzy search was performed, then
words that match a certain number of characters with words from your query,
will be highlighted in the same manner.

=head1 HOW DO THE PERL MODULES FIT IN

As you have seen above, all aspects of NexTrieve are handled through XML.
However, using XML may not be your strong point as a developer.  Therefore
the NexTrieve::xxx Perl modules were developed.  They allow access to
(almost) all aspects of NexTrieve without having to get your hands "dirty"
with XML.

This short introduction will basically take the order in which a developer
usually uses any of the NexTrieve::xxx modules.

=head2 Typical flow in lifetime of search service

                                NexTrieve
                                    |
     /-------> NexTrieve::HTML/RFC822/Mbox/Message/DBI/PDF/own
     |                              |
     |                     NexTrieve::Resource
     |                              |
     |                      NexTrieve::Index
     |                              |
     |                 NexTrieve::Daemon (optional)
     |                              |
     |            /---> NexTrieve::Search/Query
     |            |                 |
     |            |      NexTrieve::Hitlist/Hit
     |            |                 |
     |            \--- search ------|
     |                              |
     \---------------- update ------|
                                    |
                      NexTrieve::Querylog/Replay

=head2 NexTrieve.pm

The main module is the NexTrieve.pm module itself.  It is of little use by
itself as it is mainly a library of methods and subroutines that are used
by all of the other NexTrieve::xxx modules.  All of the other NexTrieve::xxx
modules directly inherit from the NexTrieve.pm module, which means that any
method that is defined within NexTrieve.pm, can also be used by any of the
other methods.  When applicable, of course.

The main function of the NexTrieve.pm module from an execution point of view,
is the ability to create a NexTrieve object.  From such a NexTrieve object,
all other objects will be created.  This is how you would create a NexTrieve
object in a Perl script:

 #!/usr/bin/perl
 use NexTrieve;
 $ntv = NexTrieve->new;

Contrary to many other Perl modules, this is the B<only> time you call the
method "new": all other objects are created using (differently) named methods
on either the NexTrieve object or on other NexTrieve::xxx objects.  For
example, to create a NexTrieve::Resource object, you would call the "Resource"
method on a NexTrieve object, like this:

 $resource = $ntv->Resource( filename );

where "$ntv" is the NexTrieve object and "$resource" is the newly created
NexTrieve::Resource object.  As another example, to create a NexTrieve::Hitlist
object (representing the result of a search query), you would typically call
the "Hitlist" method on a NexTrieve::Search object thus:

 $hitlist = $search->Hitlist( $query );

where "$search" is a NexTrieve::Search object, "$query" is a NexTrieve::Query
object and "$hitlist" is a NexTrieve::Hitlist object.

=head2 Filter modules

Before you can do any searching, you must first index content with NexTrieve
(as described above).  These Perl modules allow you to create document
sequences from several input sources:

 - NexTrieve::DBI       convert DBI statement handle to document sequence
 - NexTrieve::HTML      convert HTML-files to document sequence
 - NexTrieve::Mbox      convert messages in Unix mailboxes to docseq
 - NexTrieve::Message   convert Mail::Message object(s) to document(s)
 - NexTrieve::PDF       convert PDF-files to document sequence
 - NexTrieve::RFC822    convert messages in seperate files to docseq

When you are using the NexTrieve::RFC822 or the NexTrieve::Message module, you
can specify which lines in the header should become which attribute and/or text
type.  This allows you to e.g. specify that the Subject: line of a message
should be stored in the document as a <title> text type.

More modules will be added in the future.  And some modules will be enhanced.
Of course, you are invited to add modules with your own conversions.  Or
suggest modules for development or enhancements to existing modules.

If you are creating your own filter modules, you may wish to make use of
these "basic" filtering modules:

 - NexTrieve::Document  create your own document XML
 - NexTrieve::Docseq    create document sequence from documents

Of course, you are completely free to create your own XML in any way or
manner that you want.  By using these modules however, a lot of the nitty
gritty of XML, such as well-formedness and character encoding issues, are
handled transparently for you.

Anyway, the filter modules all have a Docseq method that creates a
NexTrieve::Docseq object for the document sequence that is generated by
the filter.  The document sequence is most commonly saved as a file
somewhere with the "write_file" method.

Most of the standard filter modules allow you to specify which attributes
and text types should be expected in a document.  Since these need to be
specified in the NexTrieve resource file, most of these modules contain
a "Resource" method that will create a basic NexTrieve::Resource object
for you, using the attribute and text type definitions that you already
specified when using the filter module.

=head2 NexTrieve::Resource.pm

The NexTrieve::Resource object allows you to handle all aspects of the
resource file that are important in a Perl environment.  It allows you to
create an object that generates the XML so that a NexTrieve program such
as "ntvindex" knows where and how to create its index.

It also allows you to create a NexTrieve::Resource object from the XML
that was previously stored in a file.

The NexTrieve::Resource is vital for the creation of a NexTrieve::Index
or a NexTrieve::Search object for "on demand" searching.  Either you
create a NexTrieve::Resource yourself, e.g.:

 $resource = $ntv->Resource( filename );

or you let the NexTrieve::Index and NexTrieve::Search objects create one
for you internally.

=head2 NexTrieve::Index.pm

Once there is a document sequence saved in a file and we have an index
directory, the NexTrieve::Index object can then be used to create the
index from the document sequence.  This can be as simple as:

 $index = $ntv->Index( $resource );
 $index->index( filename ) || die $index->result;

where "$resource" is the NexTrieve::Resource object that describes the
attributes and text types to be expected and where the index directory
is located.  The input parameters to method "index" are the filenames of
any document sequences that need to be indexed.  You can use method
"result" afterwards to inspect any output that was given by the "ntvindex"
program, especially if something has gone wrong.

=head2 NexTrieve::Daemon.pm

If you decide to run your search service in the "at your service" mode,
you can use the NexTrieve::Daemon object to call the "ntvsearchd" program.
It allows you to start the search service, check if it's running and stop
it if necessary.  A NexTrieve::Daemon object is created by specifying the
resource object that should be used, as well as (the host and) port on
which the search service should be running.  A typical way of starting a
search service would be:

 $daemon = $ntv->Daemon( $resource,'localhost:3333' );
 $daemon->start;

This would start the search service on port "3333" on the "localhost"
interface of the server.  This is usually the safest way of handling a
search service if you want to control access to the search service
completely.

=head2 NexTrieve::Search.pm

The NexTrieve::Search object gives you a transparant way of performing
search queries, either using the "on demand" mode or with the "at your
service" mode of operation.  If the "on demand" mode is to be used, then
a NexTrieve::Resource object must be made available upon creation:

 $search = $ntv->Search( $resource );

If the "at your service" mode of operation is needed, then only the
host and port specification is sufficient:

 $search = $ntv->Search( 'localhost:3333' );

=head2 NexTrieve::Query.pm

The NexTrieve::Query object allows you to create the (rather complicated)
XML that is needed to specify a query.  This is usually done by creating
a NexTrieve::Query object beforehand:

 $query = $ntv->Query( {
  constraint   => 'date < 20020101',
  texttype     => ['title','200'],
 } );

By "throwing" the NexTrieve::Query object into the NexTrieve::Search object,
you obtain the result of a search, i.e. the NexTrieve::Hitlist object.

=head2 NexTrieve::Hitlist/Hit.pm

Performing a search query is now simple: the NexTrieve::Hitlist object is
created thus:

 $hitlist = $search->Hitlist( $query );

The NexTrieve::Hitlist object contains the meta-information of the result of
the query (such as number of hits found) and the information about each
seperate hit.  Accessing the information about a specific hit is done with
the NexTrieve::Hitlist::Hit.pm object, that is created from the
NexTrieve::Hitlist object, e.g. in this manner:

 $firsthit = $hitlist->firsthit;
 $lasthit = $hitlist->lasthit;
 print "Hits $firsthit-$lasthit:<BR>\n";
 foreach my $hit ($hitlist->Hits) { # $hit is a NexTrieve::Hitlist::Hit
   $ordinal = $hit->ordinal;
   $preview = $hit->preview;
   ($filename,$date) = $hit->attributes( qw(filename date) );
   print <<EOD;
 $ordinal. $preview<BR>
 (<A HREF="$filename">, last changed $date)<BR><BR>
 EOD
 }

The above is an example of how this could be implemented in a web-based
search service which is supposed to print HTML on stdout (which is how
most web-servers operate).  Of course, you are free to handle the result
of the XML in any way or form.  A special feature of the NexTrieve::Hitlist
module allows you to save the hitlist XML directly into a file if you are
using an external XML processor such as "xsltproc".  This could be done
like this:

 $search->Hitlist( $query,filename.xml );
 system( "xsltproc stylesheet.xsl filename.xml" );

=head1 POSTPROCESSING QUERIES

Sometimes you want to know what types of queries were done on your search
service and the results that were given.

=head2 NexTrieve::Querylog.pm

When the "at your service" mode of operation is used for search queries,
it is possible to have a "query log" created which stores a timestamp and
the query that was performed.

The NexTrieve::Querylog module creates an object for a single query log
file.  You can use this to calculate statistics about the search queries
that have been performed during the lifetime of the server process.

=head2 NexTrieve::Replay.pm

The NexTrieve::Replay object was created to allow for debugging, development
and research of queries.  It basically takes a NexTrieve::Search and a
NexTrieve::Querylog object and creates subsequent NexTrieve::Hitlist objects
for all of the queries that were stored in the query log.

=head1 CONCLUSION

Hopefully you have now a better grasp of what the NexTrieve programs can do,
how they work with XML and how you can use the Perl NexTrieve::xxx modules
to B<not> have to deal with XML.

=head1 AUTHOR

Elizabeth Mattijsen, <liz@dijkmat.nl>.

Please report bugs to <perlbugs@dijkmat.nl>.

=head1 COPYRIGHT

Copyright (c) 1995-2002 Elizabeth Mattijsen <liz@dijkmat.nl>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.nextrieve.com, the NexTrieve.pm and the other NexTrieve::xxx modules.

=cut
