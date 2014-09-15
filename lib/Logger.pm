package Logger;
use strict;
use warnings;

use Exporter qw(import);

our @EXPORT_OK = qw( Log
                     LogError
                   );

use FindBin qw($Bin);
use lib "$Bin/lib";
use Data::Dumper;
use Time::localtime;


sub Log
{
  my $msg = shift;
  my $time = timestamp();
  my $filename = 'log.txt';
  open(my $fh, '>>', $filename) or die "Could not open file '$filename' $!";
  #print $fh "\[$time\]: $msg\n";
  print $fh "$msg\n";
  close $fh;
}

sub LogError
{
  my $msg = shift;
  my $time = timestamp();
  my $filename = 'error.txt';
  open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
  #print $fh "\[$time\]: $msg\n";
  print $fh "$msg\n";
  close $fh;
}

sub timestamp
{
  my $t = localtime;
  return sprintf( "%04d-%02d-%02d_%02d-%02d-%02d",
                    $t->year + 1900, $t->mon + 1, $t->mday,
                    $t->hour, $t->min, $t->sec );
}