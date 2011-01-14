use strict;
use Campfire; # DEPEND
use Getopt::Long;

my $rcfile = "$ENV{HOME}/.campfirerc";
my $host;
my $auth;
my $tail = 10; # lines of backlog to show
my $callback = \&print_message;
my $verbose;

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
  'v|verbose!' => \$verbose,
) or exit 100;

my $campfire = Campfire->new($host, $auth);

my @rooms = $campfire->presence;
foreach my $room (@rooms) {
  print STDERR "Monitoring room: ", $room->name, "\n" if $verbose;
  $callback->($_, $room) foreach $room->recent($tail);
  $room->stream($callback);
}

$campfire->run_streams;

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
  $callback = eval <<EOF;
  sub {
    my (\$message, \$room) = \@_;
    $code
  }
EOF
  $@ and die $@;
}
