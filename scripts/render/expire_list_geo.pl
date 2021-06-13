#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Std;
use Math::Trig; 

my $options = {};
getopts("m:s:t:x:X:y:Y:z:Z:d:T:h", $options);

if ($options->{h}) {
  print "options: (z,Z - required, no checks, small letters should be less)\n";
  print "  -m <m>         name of map (defaults to 'ajt')\n";
  print "  -s             socket (defaults to '/var/run/renderd/renderd.sock')\n";
  print "  -t             tile dir (defaults to '/var/lib/mod_tile/')\n";
  print "  -x <x>, -X <x> start and end longitude (in geographic coordinates, WGS84)\n";
  print "  -y <y>, -Y <y> start and end latitude (in geographic coordinates, WGS84)\n";  
  print "  -z <z>, -Z <z> start and end level value\n";
  print "  -d             delete from level (defaults to '15')\n";
  print "  -T             touch from level (defaults to '14')\n";
  print "\n";
  exit;
}

my ($z, $Z);
my $bulkSize=8;
if (($options->{x} || $options->{x}==0) &&
    ($options->{X} || $options->{X}==0) &&
    ($options->{y} || $options->{y}==0) && 
    ($options->{Y} || $options->{Y}==0) &&
    ($options->{z} || $options->{z}==0) && 
    ($options->{Z} || $options->{Z}==0))
{
  print "\nRendering started at: ";
  system("date");
  print("\n");
  $z = $options->{z};
  $Z = $options->{Z};

  my ($zoom, $x, $X, $y, $Y, $cmd, $n);
  $zoom = 1 << $options->{Z};
  $x = int($zoom * ($options->{x} + 180) / 360);
  $X = int($zoom * ($options->{X} + 180) / 360);
  $y = int($zoom * (1 - log(tan($options->{y}*pi/180) + sec($options->{y}*pi/180))/pi)/2);
  $Y = int($zoom * (1 - log(tan($options->{Y}*pi/180) + sec($options->{Y}*pi/180))/pi)/2);
  #some stupid magic: aligning max range values to the border of meta-bundles (caused by internal bug of render_list)
  $X=(int($X/$bulkSize)+1)*$bulkSize-1;
  $y=(int($y/$bulkSize)+1)*$bulkSize-1;
  $n = 3;

  open(FH, '>', "/tmp/tiles.".$options->{Z}) or die $!;
  for my $ix ($x..$X)
  {
    #be careful! y and Y used in reversed order
    for my $iy ($Y..$y)
    {
      print FH $zoom."/".$ix."/".$iy."\n";
    }
  }
  close (FH);
  $cmd="cat /tmp/tiles.".$options->{Z}." | render_expired -z ".$options->{z}." -Z ".$options->{Z};
  $cmd = $cmd." -n ".$n;
  if ($options->{m}) {$cmd = $cmd." -m ".$options->{m}} else {$cmd = $cmd." -m ajt"};
  if ($options->{s}) {$cmd = $cmd." -s ".$options->{s}} else {$cmd = $cmd." -s /var/run/renderd/renderd.sock"};
  if ($options->{t}) {$cmd = $cmd." -t ".$options->{t}} else {$cmd = $cmd." -t /var/lib/mod_tile/"};
  if ($options->{d}) {$cmd = $cmd." -d ".$options->{d}} else {$cmd = $cmd." -d 15"};
  if ($options->{T}) {$cmd = $cmd." -T ".$options->{T}} else {$cmd = $cmd." -T 14"};
  $cmd = $cmd." 2>&1 | logger";
  print $cmd."\n";
  system($cmd);
  print ("\n");
};
