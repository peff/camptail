package Campfire::Room;
use strict;
use base qw(Campfire::Base); # DEPEND
use Campfire::Message; # DEPEND

sub _accessor { Campfire::Base::_accessor @_ }
sub name { _accessor(name => @_) }
sub id { _accessor(id => @_) }

sub recent {
  my $self = shift;
  my $limit = shift;
  my $since = shift || $self->{last_message};

  my $xml = $self->{parent}->_get(
    join('/', 'room', $self->id, 'recent'),
    (defined $limit ? (limit => $limit) : ()),
    (defined $since ? (since_message_id => $since) : ()),
  );

  return unless exists $xml->{messages}->{message};

  my @messages = map { Campfire::Message->new_from_xml($_, $self->{parent}) }
                 @{$xml->{messages}->{message}};
  $self->{last_message} = $messages[-1]->id
    unless !@messages;

  return @messages;
}

sub transcript {
  my $self = shift;
  my $ymd = shift;
  my $since = shift;

  my $xml = $self->{parent}->_get(
    join('/', 'room', $self->id, 'transcript', $ymd)
  );

  return unless exists $xml->{messages}->{message};

  my @messages = map { Campfire::Message->new_from_xml($_, $self->{parent}) }
                 @{$xml->{messages}->{message}};
  if (defined $since) {
    @messages = grep { $_->id > $since } @messages;
  }
  return @messages;
}

sub stream {
  my $self = shift;
  my $cb = shift;
  my $buffer;
  $self->{parent}->_stream(
    join('/', 'room', $self->id, 'live.xml'),
    sub { $self->_stream_cb($cb, \$buffer, @_) }
  );
}

sub _stream_cb {
  my ($self, $cb, $buffer, $new) = @_;

  $$buffer .= $new;
  while ($$buffer =~ s{^\s*(<message>.*?\n</message>)\n}{}s) {
    my $xml = XML::Smart->new($1);
    $cb->(
      Campfire::Message->new_from_xml($xml->{message}, $self->{parent}),
      $self
    );
  }
}

sub enter {
  my $self = shift;
  $self->{parent}->_post(join('/', 'room', $self->id, 'join'));
}

1;
