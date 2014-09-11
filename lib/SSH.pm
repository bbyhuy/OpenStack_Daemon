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

sub plinkExecute
{
  my $command = shift;
  my $plink = "$Bin/plink.exe";

  my @sourcedcmd = `$plink -pw abc123 root\@localhost \"source /root/keystonerc_admin && $command\"`;
  return (\@sourcedcmd);
}