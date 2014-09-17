package Nova;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw( get_instances
                     start_server
                     stop_server
                     keep_active
                     get_networks
                   );

use FindBin qw($Bin);
use lib "$Bin/lib";
use Logger qw (Log LogError);
use SSH qw (plinkExecute);
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
  my $output = plinkExecute("nova list");
  my $instances = [];

  foreach my $index (0 .. $#$output)
  {
    if($output->[$index] =~ m/net\d+/ || $output->[$index] =~ m/ERROR/i)
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
      if($metadata[2] =~ m/ERROR/i)
      {
        $subnet = "";
        $floatip = "";
      }
      elsif($metadata[5] =~ m/\=([^,]+),\s+([^\s]+)/)
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

  return $instances;
}

sub remove_errored
{
  my $instances = get_instances();
  for my $index (0 .. $#$instances)
  {
     print "\n$instances->[$index]->{Status}\n\n";
    if($instances->[$index]->{Status} eq 'ERROR')
    {

      delete_instance($instances->[$index]->{Name});
    }
  }
}
sub keep_created
{
  tie my @array, 'Tie::File', "login.config" or die "Could not open login.config: $!";
  my $min_created = $array[3];
  untie @array;
  my $instances = get_instances();
  my @InstanceNames = ( "MY-FIRST-VM",
                        "MY-SECOND-VM",
                        "MY-THIRD-VM",
                        "MY-FOURTH-VM",
                        "MY-FIFTH-VM"
                      );

  if($#$instances < $min_created)
  {
    my $images = Nova::get_images();
    my $networks = Nova::get_networks();
    foreach my $name (@InstanceNames)
    {
      for my $index (0 .. $#$instances)
      { 
        if($instances->[$index]->{Name} eq $name)
        {
          last;
        }
        elsif($instances->[$index]->{Name} ne $name && $index == $#$instances)
        {
          Log("Creating Instance: $name");
          Nova::create_instance($name, $images, $networks);
          sleep 30;
          last;
        }
        else
        {
          next; 
        }
      }
    }
  }
  else
  {
    Log("Max of 5 Instances Are Present");
  }
}

sub keep_active
{
  tie my @array, 'Tie::File', "login.config" or die "Could not open login.config: $!";
  my $ActiveNum = $array[2];
  untie @array;
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
        elsif($instances->[$index]->{Status} eq 'ERROR')
        {
          delete_instance($instances->[$index]->{Name});
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
  my $output = plinkExecute("nova start $server");
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
  my $output = plinkExecute("nova stop $server");
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
  my $output = plinkExecute("nova show $server");
  #print Dumper $output;
  if(grep /$togrep/, @$output){
    return 1;
  }
  else{
    return 0;
  }
}

sub get_networks
{
  my $output = plinkExecute("nova net-list");
  my $networks = [];

  foreach my $network (@$output)
  {
    if($network =~ m/\|\s+([A-Za-z0-9\-]+)\s+/i)
    {
      if($1 eq "ID"){next;}
      else
      {
        push @$networks, $1;
      }
    }
  }
  return $networks;
}

sub get_flavors
{
  my $output = plinkExecute("nova flavor-list");
  my $flavors = [];

  foreach my $flavor (@$output)
  {
    if($flavor =~ m/\d+\s+\|\s+m1\.([A-Za-z]+)/i)
    {
      push @$flavors, "m1.$1";
    }
  }
  return $flavors;

}

sub get_images
{
  my $output = plinkExecute("nova image-list");
  my $images = [];

  foreach my $image(@$output)
  {
    if($image =~ m/\|\s+([A-Za-z0-9\-]+)\s+/i)
    {
      if($1 eq "ID"){next;}
      else
      {
        push @$images, $1;
      }
    }
  }
  return $images;
}

 #nova boot --flavor 1 --image 9388a8ba-9272-4fe9-be47-aa28ca582fc3 --nic net-id=6926fd09-677e-4dd4-a2ff-397ac7d21bf3 MY-THIRD-VM

sub create_instance
{
  my $name = shift;
  my $images = shift;
  my $networks = shift;

  my $output = plinkExecute("nova boot --flavor 1 --image $images->[0] --nic net-id=$networks->[0] $name");
}

sub delete_instance
{
  my $name = shift;
  Log("Deleting ERROR State Instance: $name");
  my $output = plinkExecute("nova delete $name");
}