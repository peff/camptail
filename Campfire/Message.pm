package Campfire::Message;
use strict;
use base qw(Campfire::Base); # DEPEND
use overload '""' => \&as_string;

sub _accessor { Campfire::Base::_accessor @_ }
sub body { _accessor(body => @_) }
sub id { _accessor(id => @_) }
sub time { _accessor('created-at' => @_) }
sub user_id { _accessor('user-id' => @_) }
sub type { _accessor('type' => @_) }

sub user {
  my $self = shift;
  return $self->{parent}->lookup_user($self->user_id);
}

sub name {
  my $self = shift;
  return $self->user->name;
}

sub as_string {
  my $self = shift;
  my $type = $self->type;
  if ($type eq 'TimestampMessage') {
    return "Timestamp: " . $self->time;
  }
  elsif ($type eq 'KickMessage') {
    return $self->name . ' leaves';
  }
  elsif ($type eq 'EnterMessage') {
    return $self->name . ' enters';
  }
  elsif ($type eq 'LeaveMessage') {
    return $self->name . ' leaves';
  }
  elsif ($type eq 'TextMessage') {
    return '<' . $self->name . '> ' . $self->body;
  }
  elsif ($type eq 'PasteMessage') {
    my $body = $self->body;
    $body =~ s/^/  /mg;
    return '<' . $self->name . "> PASTE:\n" . $body;
  }
  elsif ($type eq 'SoundMessage') {
    return '<' . $self->name . "> SOUND: " . $self->body;
  }
  elsif ($type eq 'UploadMessage') {
    return '<' . $self->name . "> UPLOAD: " . $self->body;
  }
  elsif ($type eq 'TweetMessage') {
    my $body = $self->body;
    $body =~ s/^/  /mg;
    return '<' . $self->name . "> TWEET:\n" . $body;
  }
  elsif ($type eq 'TopicChangeMessage') {
    return '<' . $self->name . "> TOPIC: " . $self->body;
  }
  else {
    return "unknown message type: $type" .
      ($ENV{CAMPFIRE_DEBUG} ?
         ("\n" . $self->{xml}->data_pointer) :
         ""
      );
  }
}

1;
