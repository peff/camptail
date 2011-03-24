package RoomState;
use strict;
use YAML qw();
use DateTime;

sub new {
  my $self = bless {}, shift;
  $self->{data} = {};
  return $self;
}

sub load {
  my $self = shift;
  my $fn = shift;

  my $fh;
  if (!open($fh, '<', $fn)) {
    return if $!{ENOENT};
    die "unable to open $fn: $!";
  }

  my $raw = do { local $/; <$fh> };
  $self->{data} = YAML::Load($raw);
}

sub save {
  my $self = shift;
  my $fn = shift;

  my $tmp = "$fn.$$";
  open(my $fh, '>', $tmp)
    or die "unable to open $tmp for writing: $!";
  print $fh YAML::Dump($self->{data})
    or die "unable to write to $tmp: $!";
  close($fh)
    or die "unable to write to $tmp: $!";

  rename ($tmp, $fn)
      or die "unable to rename $tmp to $fn: $!";
}

sub last {
  my ($self, $room, $message) = @_;
  $self->{data}->{$room->id}->{last} = $message->id
    if $message;
  return $self->{data}->{$room->id}->{last};
}

sub day {
  my ($self, $room, $dt) = @_;
  $self->{data}->{$room->id}->{day} = $dt->ymd
    if $dt;

  local $_ = $self->{data}->{$room->id}->{day};
  return undef unless defined;
  /(\d+)-(\d+)-(\d+)/
    or die "bogus saved day format: $_";
  return DateTime->new(year => $1, month => $2, day => $3);
}

1;
