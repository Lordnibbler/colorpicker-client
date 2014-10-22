#!/usr/bin/perl

# use Device::SerialPort;
use Time::HiRes qw(usleep time);
use POSIX ":sys_wait_h";
#use LWP::Simple qw (get);

# @FIXME missing this dir in github!
$cmddir = "/home/root/halo_git/commands/";

our $NUM_LIGHTS = 5;
my $SYSTEM_ON = 0;
my $LIVE_PREVIEW = 1;

@oldRgb;
for($j = 0;$j < $NUM_LIGHTS; $j++){
  push(@{$oldRgb[$j]},(0,0,0,0));
}

# system("echo 20 > /sys/kernel/debug/omap_mux/uart1_rxd");
# system("echo 0 > /sys/kernel/debug/omap_mux/uart1_txd");
system("echo BB-UART1 > /sys/devices/bone_capemgr.9/slots");
system("stty -F /dev/ttyO1 speed 115200 ignbrk -brkint -icrnl -imaxbel -opost -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl -echoke noflsh -ixon -crtscts");

$|=1;

# Opens file whose filename is given by EXPR (> /dev/tty01), and associates it with FILEHANDLE (SERIAL)
open(SERIAL, "> /dev/ttyO1");

sysopen(PREVIEW_DATA, "/home/root/colorpicker-beaglebone/colors.txt", O_RONLY)
        or die "can't read pipe: $!";

{
  my $previous_default = select(STDOUT);  # save previous default
  select(SERIAL);
  $|++;                                   # autoflush STDERR, to be sure
  select($previous_default);              # restore previous default
}

# set all black
for(my $address = 0; $address < $NUM_LIGHTS; $address ++){
  &sendColor($address,0,0,0,0);
}

sub sendColor {
  my($address,$r,$g,$b,$v)= @_;
  $address = $address + 1;
  print SERIAL "4,$address,$r,$g,$b,$v;";
}

sub turnOffAll {
  while(waitpid(-1,WNOHANG ) >= 0) {}
  for(my $address = 0; $address < $NUM_LIGHTS; $address ++){
     &sendColor($address,0,0,0,0);
    @{$oldRgb[$address]} = (0,0,0,0);
  }
}



$start_time = time();

sub grabLiveData{
  # print @preview_data;

  $rin = '';
  vec($rin, fileno(PREVIEW_DATA), 1) = 1;
  $nfound = select($rin, undef, undef, 0);    # just check
  if ($nfound) {
    @processed_data = ();
    while($color = <PREVIEW_DATA>){
      #print $color;
      #print "Glen\n";
      if($color =~ /.*END_LINE.*/){
        # print "END_FILE FOUND\n";
        last;
      }
      if($color =~ /([0-9]+)\,([0-9]+)\,([0-9]+)\,([0-9]+)/){
        # print "$1, $2, $3, $4 found\n";
        my @rgb = ($1,$2,$3,0);
        push(@processed_data,[@rgb]);
      }
    }

    # close PREVIEW_DATA or die "bad netstat: $! $?";
    $previewLength = @processed_data;
    if( $previewLength > 0){
      my $end_time = time();
      printf("%d %.6f\n", $previewLength,$end_time - $start_time);
      $start_time = time();
      # print "$previewLength data chunks\n";
      $start =0;
      if($previewLength > $NUM_LIGHTS){
         $start = $previewLength - $NUM_LIGHTS;
      }else{
        $start = 0;
      }
      # print "i is $i, total size is $previewLength";
      $address = 0;
      for($i = $start;$i< $previewLength; $i ++){
        my @rgb = @{$processed_data[$i]};
        # print @rgb;
        # printf("address %d R= %d G=%d B=%d\n",$address,$rgb[0],$rgb[1],$rgb[2],$rgb[3]);
        &sendColor($address,$rgb[0],$rgb[1],$rgb[2],$rgb[3]);
        $address ++;
      }
      if($previewLength < $NUM_LIGHTS){
        while($address < $NUM_LIGHTS){
          &sendColor($address,0,0,0,0);
          $address ++;
        }
      }
    }
  }
}

while(1){
  if($LIVE_PREVIEW == 1){
    &grabLiveData();
  }
}
