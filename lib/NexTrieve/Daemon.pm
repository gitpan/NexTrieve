package NexTrieve::Daemon;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Daemon::ISA = qw(NexTrieve);
$NexTrieve::Daemon::VERSION = '0.31';

# Use all the other NexTrieve modules that we need always

use NexTrieve::Resource ();

# Return true value for use

1;

#------------------------------------------------------------------------

# The following methods are class methods

#------------------------------------------------------------------------

#  IN: 1 NexTrieve object
#      2 filename or XML or NexTrieve::Resource object
#      3 server:port specification (optional)
#      4 ref to hash with method/value pairs

sub _new {

# Obtain the class of the object
# Attempt to create the base object
# Handle the resource specification if there is any
# Handle the serverport specification if there is any
# Handle any method calls

  my $class = shift;
  my $self = $class->SUPER::_new( shift );
  $self->Resource( ref($_[0]) eq 'ARRAY' ? @{shift(@_)} : shift ) if @_;
  $self->serverport( shift ) if @_ and !ref($_[0]);
  $self->Set( shift ) if ref($_[0]);

# Return the object

  return $self;
} #_new

#------------------------------------------------------------------------

# OUT: 1 flag: whether it should work or not
#      2 expiration date of license ('' if not known)
#      3 software version
#      4 database version
#      5 whether threaded or no

sub executable { NexTrieve->executable( 'ntvsearchd' ) } #executable

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 whether to shut down upon DESTROYing of object

sub auto_shutdown { shift->_class_variable('auto_shutdown',@_) } #auto_shutdown

#------------------------------------------------------------------------

# OUT: 1 number of bytes read into buffers

sub initial_speedup {

# Obtain the object
# Initialize number of bytes read

  my $self = shift;
  my $bytes = 0;

# Obtain the indexdir
# If we don't have an indexdir
#  Add error and return

  my $indexdir = $self->indexdir || $self->Resource->indexdir;
  unless ($indexdir) {
    $self->_add_error(
     "Must have an indexdir if not started with same object" );
    return $bytes;
  }

# For all of the appropriate files in the indexdir
#  Attempt to open the file for reading
#  Reloop if failed
#  Add the number of bytes to the file
#  Loop while we're reading the file
#  Close the handle

  foreach my $file (<$indexdir/ref*.ntv>) {
    my $handle = $self->openfile( $file,'<' );
    next unless $handle;
    $bytes += -s $handle;
    1 while <$handle>;
    close( $handle );
  }

# Return number of bytes read

  return $bytes;
} #initial_speedup

#------------------------------------------------------------------------

#  IN: 1 port on which server is running (default: started with or serverport)
# OUT: 1 PID of daemon after successful startup

sub pid {

# Obtain the object
# Create the field name
# Return the pid from the object or go find it if not in object or specific port

  my $self = shift;
  my $field = ref($self).'::pid';
  return @_ ? $self->_findpid( @_ ) : $self->{$field} || $self->_findpid;
} #pid

#------------------------------------------------------------------------

# OUT: 1 file containing the PID after successful startup

sub pidfile { $_[0]->{ref(shift).'::pidfile'} } #pidfile

#------------------------------------------------------------------------

# OUT: 1 whether the server is alive at the given server/port

sub ping {

# Obtain the object

  my $self = shift;

# Obtain the server port specification
# If there is none
#  Add error and return

  my $serverport = $self->serverport;
  unless( $serverport ) {
    $self->_add_error( "Don't know where to ping without server:port" );
    return;
  }

# Do a dummy query and return whether a hitlist was returned

  $self->ask_server_port($serverport,<<EOD) =~ m#<ntv:hl.*</ntv:hl>#s;
<ntv:query xmlns:ntv="http://www.nextrieve.com/1.0" type="exact" totalhits="1" longform="0" showattributes="0" showpreviews="1">ping</ntv:query>
EOD
} #ping

#------------------------------------------------------------------------

sub restart {

# Obtain the object
# Stop the server
# Start it again

  my $self = shift;
  $self->stop;
  $self->start;
} #restart

#------------------------------------------------------------------------

#  IN: new server:port specification
# OUT: current/old server:port specification

sub serverport { shift->_class_variable( 'serverport',@_ ) } #serverport

#------------------------------------------------------------------------

#  IN: 1 server:port specification (default: in object)
#      2 user under which to execute as (default: no change)
# OUT: 1 the object itself (handy for oneliners)

sub start {

# Obtain the object
# Obtain the class
# Obtain the command and logfile to execute
# Return now if there was something wrong

  my $self = shift;
  my $class = ref($self);
  my ($command,$log,$indexdir) = $self->_command_log( 'ntvsearchd' );
  return $self unless $command;

# Obtain the serverport specification
# Obtain the server and port
# Make sure things are ok if only a port was specified

  my $serverport = shift || $self->serverport;
  my ($server,$port) = split( ':',$serverport );
  ($server,$port) = ('',$server) if $server =~ m#^\d+$#;

# Obtain the user (if any)
# Change to parameter if there as one specified

  my $user = shift || '';
  $user = " -u $user" if $user;

# If there was a port specified
#  Make sure that we have a server specification
#  Save the server port specification
#  Create the final command and save in the object for debugging
#  Attempt to start the daemon and return the status

  if ($port) {
    $server ||= 'localhost';
    $self->serverport( "$server:$port" );
    $self->{$class.'::command'} =
     $command = "$command -A $server -P $port -L $log$user";
    my $exit = system( $command );

#  Add error if there was a problem
#  Return the object

    $self->_add_error( "Exit status from '$command': $exit" ) if $exit;
    return $self;
  }

# Add error and return the object

  $self->_add_error( "Don't know on which port to start daemon" );
  return $self;
} #start

#------------------------------------------------------------------------

#  IN: 1 port on which server is running (default: started with or serverport)
# OUT: 1 result of killing the process (should be 1 on success)

sub stop {

# Obtain the object
# Obtain the PID
# Return now if failed

  my $self = shift;
  my $pid = $self->pid( @_ );
  return unless $pid;

# Kill the process of which we found the PID and remember # processes killed
# Remove the pid info from the object
# Give it a little while
# Return the result of the kill

  my $processes = kill( 15,$pid ); # SIGTERM
  delete( $self->{ref($self).'::pid'} );
  sleep( 1 );
  return $processes;
} #stop

#------------------------------------------------------------------------

# The following subroutines are for internal usage

#------------------------------------------------------------------------

#  IN: 1 port on which server is running (default: started with or serverport)
# OUT: 1 pid (if available)

sub _findpid {

# Obtain the object

  my $self = shift;

# Obtain the port
# Remove server part if any
# If there is no port
#  Add error an return

  my $port = shift || $self->serverport;
  $port =~ s#^.*:##;
  unless ($port) {
    $self->_add_error(
     "Must specify a port if not started with same object" );
    return;
  }

# Obtain the indexdir
# If there is no indexdir
#  Add error and return

  my $indexdir = $self->indexdir || $self->Resource->indexdir;
  unless ($indexdir) {
    $self->_add_error(
     "Must have an indexdir if not started with same object" );
    return;
  }

# Create the pid out of the indexdir and port
# If there still is no pid
#  Add error and return
  
  my $pid = $self->_pid( $indexdir,$port );
  unless ($pid) {
    $self->_add_error( "Cannot find a pidfile for port $port in $indexdir" );
    return;
  }

# Return the pid we found

  return $pid;
} #_findpid

#------------------------------------------------------------------------

#  IN: 1 indexdir
#      2 port
# OUT: 1 pid

sub _pid {

# Obtain the object
# Obtain the class
# Obtain the indexdir
# Obtain the port

  my $self = shift;
  my $class = ref($self);
  my $indexdir = shift;
  my $port = shift;

# Create the name of the PIDfile
# Try this 5 times
#  Outloop if the pidfile exists
#  Wait for a second (server might be starting)

  my $pidfile = $self->{$class.'::pidfile'} = "$indexdir/pid.$port.ntv";
  foreach( 1..5 ) {
    last if -e $pidfile;
    sleep( 1 );
  }

# Open the PIDfile
# Read the first line
# Close the PIDfile
# Return the PID

  my $handle = $self->openfile( $pidfile,'<' );
  chomp( my $pid = $self->{$class.'::pid'} = <$handle> );
  close( $handle );
  return $pid;
} #_pid

#------------------------------------------------------------------------

# The following subroutines deal with standard Perl features

#------------------------------------------------------------------------

sub DESTROY {

# Obtain the object
# Stop the daemon if so specified

  my $self = shift;
  $self->stop if $self->auto_shutdown;
} #DESTROY

#------------------------------------------------------------------------

__END__

=head1 NAME

NexTrieve::Daemon - handle NexTrieve running as a daemon

=head1 SYNOPSIS

 use NexTrieve;
 die unless NexTrieve::Daemon->executable;

 $ntv = NexTrieve->new( | {method => value} );

 # using collections
 $collection = $ntv->Collection( path );
 $daemon = $collection->Daemon( mnemonic );

 # using direct access
 $resource = $ntv->Resource( | file | xml | {method => value} );
 $daemon = $ntv->Daemon( | file | $resource, | server:port, | {method => value} );

=head1 DESCRIPTION

The Daemon object of the Perl support for NexTrieve.  Do not create
directly, but through the Daemon method of the NexTrieve or the
NexTrieve::Collection object.

=head1 CLASS METHODS

These methods are available as class methods.

=head2 executable

 $executable = NexTrieve::Daemon->executable;
 ($program,$expiration,$software,$database,$threaded) = NexTrieve::Daemon->executable;

Return information about the associated NexTrieve program "ntvsearchd".

The first output parameter contains the full program name of the NexTrieve
executable "ntvsearchd".  It contains the empty string if the "ntvsearchd"
executable could not be found or is not executable by the effective user.
Can be used as a flag.  Is the only parameter returned in a scalar context.

If this method is called in a list context, an attempt is made to execute
the NexTrieve program "ntvsearchd" to obtain additional information.  Then
the following output parameters are returned.

The second output parameter returns the expiration date of the license that
NexTrieve is using by default.  If available, then the date is returned as a
datestamp (YYYYMMDD).

The third output parameter returns the version of the NexTrieve software that
is being used.  It is a string in the form "M.m.rr", whereby "M" is the major
release number, "m" is the minor release number and "rr" is the build number.

The fourth output parameter returns the version of the internal database that
will be created by the version of the NexTrieve software that is being used.
It is a string in the form "M.m.rr", whereby "M" is the major release number,
"m" is the minor release number and "rr" is the build number.

The fifth output parameter returns a flag whether this version of the NexTrieve
software is threaded or not.

=head1 OBJECT METHODS

These methods are available to the NexTrieve::Daemon object.

=head2 Resource

 $resource = $daemon->Resource;
 $daemon->Resource( $resource | file | xml | {method => value} );

The "Resource" method is primarily intended to allow you to obtain the
NexTrieve::Resource object that is (indirectly) created when the
NexTrieve::Daemon object is created.  If necessary, it can also be used
to create a new NexTrieve::Resource object associated with the
NexTrieve::Daemon object.

See the NexTrieve::Resource module for more information.

=head1 OTHER METHODS

These methods are available to the NexTrieve::Daemon object.

=head2 auto_shutdown

 $daemon->auto_shutdown( true | false );
 $auto_shutdown = $daemon->auto_shutdown;

The "autoshutdown" method specifies whether the server process that is started
with L<start> should be automatically L<stop>ped when the NexTrieve::Daemon
object is destroyed.  By default, the server process will _not_ be shut down
when the object is destroyed.

=head2 indexdir

 $daemon->indexdir( directory );
 $directory = $daemon->indexdir;

The "indexdir" method specifies an indexdirectory B<other> than the
indexdirectory that is specified in the L<Resource> object.  By default, the
indexdirectory information from the L<Resource> object is used.

=head2 pid

 $pid = $daemon->pid;

The "pid" method returns the process-id (or PID) of the server process.  It
sets an error if the PID could not be found, in which case it will also return
undef.

=head2 pidfile

 $pidfile = $daemon->pidfile;

The "pidfile" method returns the absolute path where the file that contains
the process-id (or PID) of the server process.

=head2 ping

 $alive = $daemon->ping;

The "ping" method returns whether the server process associated with the
NexTrieve::Daemon object, is still running.

=head2 restart

 $daemon->restart;

The "restart" method indicates that the current server process associated with
the NexTrieve::Daemon object, should be stopped and a new server process,
using the specifics of the current NexTrieve::Daemon object, should be started.
Check the L<pid> method afterwards to check whether a server process has
started.  Use the L<start> method to start a server process and the L<stop>
method to stop a server process.

=head2 serverport

 $daemon->serverport( server:port | port );
 $serverport = $daemon->serverport;

The "serverport" method specifies which server address and port should be
used by the server process of this NexTrieve::Daemon object.  The input
parameter may consist of:

- just a port number

If you want to have the server process bind to the "localhost" address, then
just specifying the port number to which the server process should bind, is
enough.  See the "anyport" method of the NexTrieve.pm module to obtain a random
port number if you don't know of one yourself.

- server:port specification

If you specify a server name or IP-address and a port number seperated by a
colon, then the server process will attempt to bind to the port number and
the interface that is handling the (implicitely) specified IP-number.

=head2 start

 $daemon->start( | server:port | port, | user );

The "start" method allows you to start a server process.  The first input
parameter specifies the server:port specification in the same way as the
L<serverport> method.  If it is omitted, the settings that were created at
object creation time or of a previous call to the serverport method, will be
assumed.  See method L<stop> to stop a server process.

The second input parameter only makes sense if the user is currently "root"
(uid == 0).  If specifies the name (or uid number) of the user as which the
server process should run.  If no user is specified, it will continue to run
as the user with which this process is running.

=head2 stop

 $killed = $daemon->stop;

The "stop" method can be called to stop the server process that is associated
with the NexTrieve::Daemon object.  It returns a flag indicating whether the
attempt was successful or not.  See method L<start> to start a server process.

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
