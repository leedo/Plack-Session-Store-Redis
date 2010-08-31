package Plack::Session::Store::Redis;

use strict;
use warnings;
use parent 'Plack::Session::Store';

use Redis;
use JSON;

use Plack::Util::Accessor qw/prefix redis/;

our $VERSION = '0.01';

sub new {
  my ($class, %params) = @_;

  my $server = $ENV{REDIS_SERVER} ||
            ($params{host} || '127.0.0.1').":".
            ($params{port} || 6379);

  my $self = {
    prefix => $params{prefix} || 'session',
    redis  => Redis->new(server => $server),
  };

  bless $self, $class;
}

sub fetch {
  my ($self, $session_id) = @_;
  my $session = $self->redis->get($self->prefix."_".$session_id);

  return ($session ? decode_json $session : ())
}

sub store {
  my ($self, $session_id, $session_obj) = @_;
  $self->redis->set($self->prefix."_".$session_id, encode_json $session_obj);
}

sub remove {
  my ($self, $session_id) = @_;
  $self->redis->del($self->prefix."_".$session_id);
}

1;
