package Campfire::User;
use strict;
use base qw(Campfire::Base); # DEPEND

sub _accessor { Campfire::Base::_accessor @_ }
sub name { _accessor(name => @_) }

1;
