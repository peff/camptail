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

  my $xml = $self->{parent}->_get(
    join('/', 'room', $self->id, 'recent'),
    (defined $limit ? (limit => $limit) : ()),
    (defined $self->{last_message} ?
      (since_message_id => $self->{last_message}) :
      ()
    ),
  );

  return unless exists $xml->{messages}->{message};

  my @messages = map { Campfire::Message->new_from_xml($_, $self->{parent}) }
                 @{$xml->{messages}->{message}};
  $self->{last_message} = $messages[-1]->id
    unless !@messages;

  return @messages;
}

1;
