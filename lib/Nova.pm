package Nova;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw( get_instances
                     start_server
                     stop_server
                     keep_active
                   );

use FindBin qw($Bin);
use lib "$Bin/lib";
use Logger qw (Log LogError);
use Data::Dumper;
use Storable qw (dclone);

=begin GHOSTCOMMENT

  The purpose of this module is to be able to wrap basic OpenStack NOVA client command line
  commands. This will allow direct interaction with OpenStack without the use of any external 
  libraries. 

=end GHOSTCOMMENT
=cut

sub ExecuteCommand
{
  my $command = shift;

  my @sourcedcmd = `source /root/keystonerc_admin && $command`;
  return (\@sourcedcmd);
}

sub get_instances
{
  my $output = ExecuteCommand("nova list");
  my $instances = [];

  foreach my $index (0 .. $#$output)
  {
    if($output->[$index] =~ m/net\d+/)
    {
      my @metadata = split /\|/, $output->[$index];

      foreach my $rindex (reverse 0 .. $#metadata)
      {
        if($metadata[$rindex] !~ m/[A-Za-z0-9]/)
        {
          splice ( @metadata, $rindex, 1 );
        }
      }
      my ($subnet, $floatip);
      if($metadata[5] =~ m/\=([^,]+),\s+([^\s]+)/)
      {
        $subnet = $1;
        $floatip = $2;
      }

      @metadata = map {join(' ', split(' '))} @metadata;

      my $metahash = {
                        'ID'      => $metadata[0],
                        'Name'    => $metadata[1],
                        'Status'  => $metadata[2],
                        'Task'    => $metadata[3],
                        'Power'   => $metadata[4],
                        'Subnet'  => $subnet,
                        'FloatIP' => $floatip,
                     };
      push (@$instances, dclone($metahash));
    }
  }
  #print Dumper $instances;
  return $instances;
}

sub keep_active
{
  my $ActiveNum = shift;
  my $instances = get_instances();
  my $active = 0;

  if($instances && $ActiveNum)
  {
    if($ActiveNum <= $#$instances)
    {
      for my $index (0 .. $#$instances)
      {
        if($active == $ActiveNum)
        {
          Log("Error 0");
          return 1;
        }
        if($instances->[$index]->{Status} eq 'ACTIVE' && $instances->[$index]->{Power} eq 'Running')
        {
          $active++;
        }
        else
        {
          if(start_server($instances, $instances->[$index]->{Name}))
          {
            $active++;
          }
        }
      }
    }
    else
    {
      LogError("Insufficient Resources");
    }
  }
  else
  {
    LogError("Undefined Variables");
  }
  return 0;
}

sub start_server
{
  my $instances = shift;
  my $server = shift;

  if($instances && $server)
  {
    foreach (@$instances)
    {
      if($_->{Name} eq $server)
      {
        last;
      }
    }
  }

  #executes nova start command
  my $output = ExecuteCommand("nova start $server");
  my $timeout = 5;
  Log("Starting $server instance...");
  while ($timeout > 0)
  {
    if(show_server($instances, $server, "ACTIVE"))
    {
      Log("$server started successfully..");
      return 1;
    }
    else
    {
      sleep 5;
      $timeout--;
    }
  }
  LogError("$server failed to start");
  return 0;
}

sub stop_server
{
  my $instances = shift;
  my $server = shift;

  if($instances && $server)
  {
    foreach (@$instances)
    {
      if($_->{Name} eq $server)
      {
        last;
      }
    }
  }

  #executes nova stop command
  my $output = ExecuteCommand("nova stop $server");
  my $timeout = 5;
  Log("Stopping $server instance...");
  while ($timeout > 0)
  {
    if(show_server($instances, $server, "SHUTOFF"))
    {
      Log("$server stopped successfully..");
      return 1;
    }
    else
    {
      sleep 5;
      $timeout--;
    }
  }
  LogError("$server failed to stop");
  return 0;
}

sub show_server
{
  my $instances = shift;
  my $server = shift;
  my $togrep = shift;

  #executes nova stop command
  my $output = ExecuteCommand("nova show $server");
  #print Dumper $output;
  if(grep /$togrep/, @$output){
    return 1;
  }
  else{
    return 0;
  }
}