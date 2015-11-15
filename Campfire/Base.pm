package Campfire::Base;
use strict;

sub new_from_xml {
  my $self = bless {}, shift;
  $self->{xml} = shift;
  $self->{parent} = shift;
  return $self;
}

sub _accessor {
  my ($what, $self) = @_;
  return scalar($self->{xml}->{$what}->content);
}

1;
