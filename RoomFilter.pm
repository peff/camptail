package RoomFilter;
use strict;

sub new {
  my $self = bless {}, shift;
  foreach (@_) {
    if (/^[0-9]+$/) {
      $self->{id}->{$_} = 1;
    }
    else {
      push @{$self->{re}}, qr/$_/i;
    }
  }
  return $self;
}

sub filter {
  my $self = shift;
  return grep { $self->match($_) } @_;
}

sub match {
  my ($self, $room) = @_;

  return 1 if $self->{id}->{$room->id};

  my $name = $room->name;
  foreach my $re (@{$self->{re}}) {
    return 1 if $name =~ $re;
  }

  return 0;
}

1;
