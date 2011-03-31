use strict;
use Campfire; # DEPEND
use RoomState; # DEPEND
use RoomFilter; # DEPEND
use Getopt::Long;

binmode(STDOUT, ':utf8');

my $rcfile = "$ENV{HOME}/.camptailrc";
my $host;
my $auth;
my $tail = 10; # lines of backlog to show
my $callback = \&print_message;
my $verbose;
my @want_rooms;
my @want_rooms_commandline;
my $follow = 0;
my $grep_before;
my $grep_after;
my $state_file;
my $all;
my $days = 14;

Getopt::Long::Configure(qw(bundling pass_through));
GetOptions('c|config=s' => \$rcfile)
  or exit 100;

read_rcfile($rcfile) if -e $rcfile;

Getopt::Long::Configure(qw(no_pass_through));
GetOptions(
  'h|host=s' => \$host,
  'a|auth=s' => \$auth,
  't|tail=i' => \$tail,
  'callback=s' => \&setup_callback,
  'print' => sub { $callback = \&print_message },
  'grep=s' => \&setup_grep,
  'B=i' => \$grep_before,
  'A=i' => \$grep_after,
  'v|verbose!' => \$verbose,
  'r|room=s' => \@want_rooms_commandline,
  'f|follow!' => \$follow,
  'state=s' => \$state_file,
  'all!' => \$all,
  'd|days=i' => \$days,
) or exit 100;

my $campfire = Campfire->new($host, $auth);

my @rooms =
  @want_rooms_commandline ?
    RoomFilter->new(@want_rooms_commandline)->filter($campfire->rooms) :
  @want_rooms ?
    RoomFilter->new(@want_rooms)->filter($campfire->rooms) :
  $campfire->presence;

my $state = RoomState->new;
$state->load($state_file) if defined $state_file;

foreach my $room (@rooms) {
  if ($all) {
    my $day = $state->day($room) || DateTime->now->subtract(days => $days);
    my $end = DateTime->now->add(days => 1)->truncate(to => 'day');
    my $last = $state->last($room);
    for (; $day < $end; $day->add(days => 1)) {
      foreach my $message ($room->transcript($day->ymd('/'),
                                             $state->last($room))) {
        $callback->($message, $room);
        $state->last($room, $message);
      }
    }
    $state->day($room, DateTime->now);
  }
  else {
    foreach my $message ($room->recent($tail, $state->last($room))) {
      $callback->($message, $room);
      $state->last($room, $message);
    }
  }

  if ($follow) {
    print STDERR "Monitoring room: ", $room->name, "\n" if $verbose;
    $room->enter;
    $room->stream($callback);
  }
}

$campfire->run_streams if $follow;

$state->save($state_file) if defined $state_file;
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

sub setup_callback {
  my (undef, $code) = @_;
  if ($code =~ /^[A-za-z0-9_]+$/) {
    $code .= '(@_)';
  }
  $callback = eval <<EOF;
  sub {
    my (\$message, \$room) = \@_;
    $code
  }
EOF
  $@ and die $@;
}

{
  my $re;

  sub setup_grep {
    my (undef, $pattern) = @_;
    $re = qr/$pattern/i;
    $callback = \&grep_message;
  }

  my @window;
  my $want_after;
  sub grep_message {
    my ($message, $room) = @_;

    if ($message->body =~ $re) {
      print_message(@$_) foreach @window;
      print_message(@_);
      @window = ();
      $want_after = $grep_after;
    }
    elsif ($want_after) {
      if ($want_after) {
        print_message(@_);
        $want_after--;
      }
    }
    elsif ($grep_before) {
      push @window, [@_];
      shift @window while @window > $grep_before;
    }
  }
}
