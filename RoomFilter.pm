package RoomFilter;
use strict;

sub new {
  my $self = bless {}, shift;
  $self->{index} = { map { $_ => 1 } @_ };
  return $self;
}

sub filter {
  my $self = shift;
  return grep { $self->{index}->{$_->name} || $self->{index}->{$_->id} } @_;
}

1;
