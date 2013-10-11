package Campfire;
use strict;
use Campfire::Room; # DEPEND
use Campfire::User; # DEPEND
use XML::Smart;
use WWW::Curl::Easy;
use WWW::Curl::Multi;
use WWW::Curl::Form;
use URI;
use Memoize;

sub new {
  my $self = bless {}, shift;
  my $org = shift;
  $self->{auth} = shift;
  $self->{curl} = $self->_new_curl;
  $self->{multi} = WWW::Curl::Multi->new;
  $self->{curlid} = 0;
  $self->{url} = URI->new("https://$org.campfirenow.com");
  return $self;
}

sub presence { _get_rooms(presence => @_) }
sub rooms { _get_rooms(rooms => @_) }
sub _get_rooms {
  my $type = shift;
  my $self = shift;
  my $xml = $self->_get($type);
  return unless exists $xml->{rooms}->{room};
  return map { Campfire::Room->new_from_xml($_, $self) }
         @{$xml->{rooms}->{room}};
}

sub _new_curl {
  my $self = shift;
  my $curl = WWW::Curl::Easy->new;
  $curl->setopt(CURLOPT_USERNAME, $self->{auth});
  return $curl;
}

sub _get {
  my $self = shift;
  my $req = shift;

  my $url = $self->{url}->clone;
  $url->path("$req.xml");
  $url->query_form(@_);

  my $body;
  $self->{curl}->setopt(CURLOPT_URL, $url);
  $self->{curl}->setopt(CURLOPT_POST, 0);
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

sub _post {
  my $self = shift;
  my $req = shift;

  my $url = $self->{url}->clone;
  $url->path("$req.xml");

  my $form = WWW::Curl::Form->new;
  while (@_) {
    my $k = shift; my $v = shift;
    $form->formadd($k => $v);
  }

  my $body;
  $self->{curl}->setopt(CURLOPT_URL, $url);
  $self->{curl}->setopt(CURLOPT_HTTPPOST, $form);
  $self->{curl}->setopt(CURLOPT_WRITEDATA, \$body);

  my $r = $self->{curl}->perform;
  $r == 0
    or die join(' ',
      "unable to post to $url:",
      $self->{curl}->strerror($r),
      $self->{curl}->errbuf
    );
}

sub _stream {
  my $self = shift;
  my $req = shift;
  my $cb = shift;

  my $curl = $self->_new_curl;
  my $id = $self->{curlid}++;
  $curl->setopt(CURLOPT_PRIVATE, $id);
  $curl->setopt(CURLOPT_WRITEFUNCTION, sub { $cb->(@_); return length $_[0] });
  $curl->setopt(CURLOPT_URL, "https://streaming.campfirenow.com/$req");

  $self->{handles}->{$id} = $curl;
  $self->{multi}->add_handle($curl);
}

sub run_streams {
  my $self = shift;

  $self->{multi}->perform
    or return;

  while (1) {
    my ($rfd, $wfd, $efd) =
      map {
        my $bits;
        vec($bits, $_, 1) = 1 foreach @$_;
        $bits
      } $self->{multi}->fdset;
    select($rfd, $wfd, $efd, undef);

    $self->{multi}->perform
      or last;

    while (my ($id, $rc) = $self->{multi}->info_read) {
      delete $self->{handles}->{$id};
    }
  }
}

memoize('lookup_user');
sub lookup_user {
  my $self = shift;
  my $id = shift;
  my $xml = $self->_get("users/$id");
  return Campfire::User->new_from_xml($xml->{user});
}

1;
