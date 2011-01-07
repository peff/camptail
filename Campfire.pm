package Campfire;
use strict;
use Campfire::Room; # DEPEND
use Campfire::User; # DEPEND
use XML::Smart;
use WWW::Curl::Easy;
use URI;
use Memoize;

sub new {
  my $self = bless {}, shift;
  my $org = shift;
  my $auth = shift;
  $self->{curl} = WWW::Curl::Easy->new;
  $self->{curl}->setopt(CURLOPT_USERNAME, $auth);
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

  my $body;
  $self->{curl}->setopt(CURLOPT_URL, $url);
  $self->{curl}->setopt(CURLOPT_WRITEDATA, \$body);

  my $r = $self->{curl}->perform;
  $r == 0
    or die join(' ',
      "unable to fetch $url:",
      $self->{curl}->strerror($r),
      $self->{curl}->errbuf
    );

  return XML::Smart->new($body);
}

memoize('lookup_user');
sub lookup_user {
  my $self = shift;
  my $id = shift;
  my $xml = $self->_get("users/$id");
  return Campfire::User->new_from_xml($xml->{user});
}

1;
