package RoomState;
use strict;
use YAML qw();

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

1;
