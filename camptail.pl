use strict;
use Campfire; # DEPEND

my $RCFILE = "$ENV{HOME}/.campfirerc";
my $host;
my $auth;
my $tail = 10; # lines of backlog to show
my $delay = 15; # delay in seconds between polls
my $callback = \&print_message;
read_rcfile($RCFILE) if -e $RCFILE;

my $campfire = Campfire->new($host, $auth);

my @rooms = $campfire->presence;
foreach my $room (@rooms) {
  $callback->($_, $room) foreach $room->recent($tail);
}

while (1) {
  sleep($delay);
  foreach my $room (@rooms) {
    $callback->($_, $room) foreach $room->recent;
  }
}
exit 0;

sub read_rcfile {
  my $fn = shift;
  open(my $fh, '<', $fn)
    or die "unable to open $fn: $!";
  my $data = do { local $/; <$fh> };
  eval "#line 1 $fn\n$data";
  $@ and die $@;
}

{
  my $last_room;
  sub print_message {
    my ($message, $room) = @_;

    if ($room != $last_room) {
      print "==> ", $room->name, " <==\n";
      $last_room = $room;
    }

    print $message, "\n";
  }
}
