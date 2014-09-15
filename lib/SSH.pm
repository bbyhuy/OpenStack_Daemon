package SSH;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw( 
                     plinkExecute
                   );

use FindBin qw($Bin);
use lib "$Bin/lib";
use Data::Dumper;
use Time::localtime;
use Tie::File;

sub plinkExecute
{
  my $command = shift;
  my $plink = "$Bin/plink.exe";

  tie my @array, 'Tie::File', "login.config" or die "Could not open login.config: $!";


  my @sourcedcmd = `$plink -pw $array[1] root\@$array[0] \"source /root/keystonerc_admin && $command\"`;
  #print Dumper @sourcedcmd;
  return (\@sourcedcmd);
}