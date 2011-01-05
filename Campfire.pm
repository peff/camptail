package Campfire;
use strict;
use Campfire::Room; # DEPEND
use Campfire::User; # DEPEND
use XML::Smart;
use LWP::UserAgent;
use URI;
use Memoize;

sub new {
  my $self = bless {}, shift;
  my $org = shift;
  my $auth = shift;
  $self->{ua} = LWP::UserAgent->new;
  $self->{ua}->credentials(
    "$org.campfirenow.com:443", 'Application',
    $auth => 'X'
  );
  $self->{url} = URI->new("https://$org.campfirenow.com");
  return $self;
}

sub presence {
  my $self = shift;
  my $xml = $self->_get('presence');
  return unless exists $xml->{rooms}->{room};
  return map { Campfire::Room->new_from_xml($_, $self) }
         @{$xml->{rooms}->{room}};
}

sub _get {
  my $self = shift;
  my $req = shift;

  my $url = $self->{url}->clone;
  $url->path("$req.xml");
  $url->query_form(@_);

  my $response = $self->{ua}->get($url);
  $response->is_success
    or die "unable to fetch $url: " . $response->status_line;

  return XML::Smart->new($response->decoded_content);
}

memoize('lookup_user');
sub lookup_user {
  my $self = shift;
  my $id = shift;
  my $xml = $self->_get("users/$id");
  return Campfire::User->new_from_xml($xml->{user});
}

1;
