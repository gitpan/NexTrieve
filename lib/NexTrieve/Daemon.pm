package NexTrieve::Daemon;

# Make sure we do everything by the book
# Set modules to inherit from
# Set version information

use strict;
@NexTrieve::Daemon::ISA = qw(NexTrieve);
$NexTrieve::Daemon::VERSION = '0.02';

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
  $self->Resource( shift ) if @_;
  $self->serverport( shift ) if @_ and !ref($_[0]);
  $self->Set( shift ) if ref($_[0]);

# Return the object

  return $self;
} #_new

#------------------------------------------------------------------------

# OUT: 1 flag whether associated NexTrieve executable installed and executable

sub executable { -x NexTrieve->new->NexTrievePath.'/ntvsearchd' } #executable

#------------------------------------------------------------------------

# The following methods change the object

#------------------------------------------------------------------------

#  IN: 1 whether to shut down upon DESTROYing of object

sub auto_shutdown { shift->_class_variable('auto_shutdown',@_) } #auto_shutdown

#------------------------------------------------------------------------

# OUT: 1 PID of daemon after successful startup

sub pid {

# Obtain the object
# Return the pid from the object or go find it

  my $self = shift;
  return $self->{ref($self).'::pid'} || $self->_findpid;
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

#  IN: new server:port specification
# OUT: current/old server:port specification

sub serverport { shift->_class_variable( 'serverport',@_ ) } #serverport

#------------------------------------------------------------------------

#  IN: 1 server:port specification
#      2 user under which to execute as (default: no change)
# OUT: 1 the object itself

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
     $command = "$command -A $server -P $port -L $log$user 2>/dev/null";
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
  my $pid = $self->pid;
  return unless $pid;

# Kill the process of which we found the PID and remember # processes killed
# Give it a little while
# Return the result of the kill

  my $processes = kill( 15,$pid ); # SIGTERM
  sleep( 1 );
  return $processes;
} #stop

#------------------------------------------------------------------------

# The following subroutines are for internal usage

#------------------------------------------------------------------------

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

  my $handle = $self->openfile( $pidfile );
  my $pid = $self->{$class.'::pid'} = <$handle>;
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

NexTrieve::Daemon - handle NexTrieve as a daemon

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

=head1 METHODS

These methods are available to the NexTrieve::Daemon object.

=head2 auto_shutdown

 $daemon->auto_shutdown( 1 );
 $auto_shutdown = $daemon->auto_shutdown;

=head2 indexdir

 $daemon->indexdir( directory );
 $directory = $daemon->indexdir;

=head2 Resource

 $resource = $daemon->Resource( | file | xml | {method => value} );

=head2 serverport

 $daemon->serverport( server:port | port );
 $serverport = $daemon->serverport;

=head2 pid

 $pid = $daemon->pid;

=head2 pidfile

 $pidfile = $daemon->pidfile;

=head2 ping

 $alive = $daemon->ping;

=head2 start

 $exit = $daemon->start( | server:port | port, | user );

=head2 stop

 $killed = $daemon->stop;

=head1 AUTHOR

Elizabeth Mattijsen, <liz@nextrieve.com>.

Please report bugs to <perlbugs@nextrieve.com>.

=head1 COPYRIGHT

Copyright (c) 1995-2002 Elizabeth Mattijsen <liz@nextrieve.com>. All rights
reserved.  This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

http://www.nextrieve.com, the NexTrieve.pm and the other NexTrieve::xxx modules.

=cut
