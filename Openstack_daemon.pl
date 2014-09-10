#!/usr/bin/perl
use strict;
use warnings;

use FindBin qw($Bin);
use lib "$FindBin::Bin/lib";
use Data::Dumper;
use Nova qw(get_instances start_server stop_server keep_active);
use Logger qw(Log LogError);

while(42)
{
  if(-e "$Bin/boom")
  {
    Nova::keep_active(1);
    #Log("Found Boom");
  }
  elsif(-e "$Bin/kill")
  {
    last;
  }
  else
  {
    Log("No Boom Found...Sleeping for 5 Minutes....");
  }
  sleep 360;        
}



#my $instances = Nova::get_instances();
#OpenStack::Nova::start_server($ssh, $instances, "MY-SECOND-VM");
#OpenStack::Nova::stop_server($ssh, $instances, "MY-SECOND-VM");

sleep 10;
exit;