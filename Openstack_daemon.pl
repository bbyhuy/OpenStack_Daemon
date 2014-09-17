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
    Log("Daemon is Active");
    Nova::remove_errored();
    Nova::keep_active();
    Nova::keep_created();
    Log("Resting for 360 Seconds")
  }
  elsif(-e "$Bin/kill")
  {
    last;
  }
  else
  {
    Log("Daemon at Rest");
  }
  sleep 360;        
}

sleep 10;
exit;