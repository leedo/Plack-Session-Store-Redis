package Plack::Session::Store::Redis;

use strict;
use warnings;
use parent 'Plack::Session::Store';

use Redis;
use JSON;

use Plack::Util::Accessor qw/prefix redis/;

=head1 NAME

Plack::Session::Store::Redis - Redis based session store for Plack apps.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware::Session;
  use Plack::Session::Store::Redis;

  my $app = sub { ... };

  builder {
    enable 'Session', store => 'Redis';
    $app;
  };

=head1 DESCRIPTION

This module will store Plack session data on a redis server.

=head1 METHODS

=head2 new( %params )

Create a instance of this module. No parameters are required, but there are a few defaults that can be changed. You can set the IP address of the server with the 'host' option, and the port with 'port'. By default all of the keys in Redis will be prefixed with "session", but this can be changed with the 'prefix' option.

=cut

sub new {
  my ($class, %params) = @_;

  my $server = $ENV{REDIS_SERVER} ||
            ($params{host} || '127.0.0.1').":".
            ($params{port} || 6379);

  my $self = {
    prefix => $params{prefix} || 'session',
    redis  => Redis->new(server => $server),
    server => $server,
  };

  bless $self, $class;
}

=head2 fetch( $session_id )

Fetches a session object from the database.

=cut

sub fetch {
  my ($self, $session_id) = @_;

  my $session = $self->_exec("get", $session_id);

  return ($session ? decode_json $session : ())
}

sub _reconnect {
  my $self = shift;
}

sub _exec {
  my ($self, $command, $session, @args) = @_;
  unshift @args, $self->prefix."_".$session;

  my $ret = eval {$self->redis->$command(@args)};

  if ($@) {
    $self->redis(Redis->new(server => $self->server));
    $ret = $self->redis->$command(@args);
  }

  return $ret;
}

=head2 store( $session_id, \%session_obj )

Stores a session object in the database.

=cut

sub store {
  my ($self, $session_id, $session_obj) = @_;

  $self->_exec("set", $session_id, encode_json $session_obj);
}

=head2 remove( $session_id )

Removes the session object from the database.

=cut

sub remove {
  my ($self, $session_id) = @_;

  $self->_exec("del", $session_id);
}

=head1 AUTHOR

Lee Aylward, C<< <leedo at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-plack-session-store-redis at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Plack-Session-Store-Redis>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Plack::Session::Store::Redis


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Plack-Session-Store-Redis>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Plack-Session-Store-Redis>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Plack-Session-Store-Redis>

=item * Search CPAN

L<http://search.cpan.org/dist/Plack-Session-Store-Redis/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Lee Aylward.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Plack::Session::Store::Redis
