package Net::Async::Webservice::Common::SyncAgentWrapper;
use Moo;
use Net::Async::Webservice::Common::Types 'SyncUserAgent';
use HTTP::Request;
use HTTP::Request::Common qw();
use Future;
use Carp;
use Scalar::Util 'blessed';
use namespace::autoclean;

# ABSTRACT: minimal wrapper to adapt a sync UA

=head1 DESCRIPTION

This class wraps an instance of L<LWP::UserAgent> (or something that
looks like it) to allow it to be used as if it were a
L<Net::Async::HTTP>. It is I<very> limited at the moment, please read
all of this document and, if you need more power, submit a bug
request.

An instance of this class will be automatically created if you pass a
L<LWP::UserAgent> (or something that looks like it) to the constructor
for a class doing
L<Net::Async::Webservice::Common::WithUserAgent>.

=attr C<ua>

The actual user agent instance.

=cut

has ua => (
    is => 'ro',
    isa => SyncUserAgent,
    required => 1,
);

=method C<do_request>

Delegates to C<< $self->ua->request >>, and returns an immediate
L<Future>. It supports just a few of the options you can pass to the
actual method in L<Net::Async::HTTP>. These are supported:

=for :list
* C<< request => >> L<HTTP::Request>
* C<< host => >> string
* C<< port => >> int or string
* C<< uri => >> L<URI> or string
* C<< method => >> string
* C<< content => >> string or arrayref
* C<< content_type => >> string
* C<< user => >> string
* C<< pass => >> string
* C<< fail_on_error => >> boolean

=cut

sub do_request {
    my ($self,%args) = @_;

    if( my $uri = delete $args{uri} ) {
        %args = $self->_make_request( $uri, %args );
    }

    my $request = $args{request};
    my $fail = $args{fail_on_error};

    my $response = $self->ua->request($request);
    if ($fail && ! $response->is_success) {
        return Future->new->fail($response->status_line,'http',$response,$request);
    }
    return Future->wrap($response);
}

sub _make_request
{
   my $self = shift;
   my ( $uri, %args ) = @_;

   if( !ref $uri ) {
      $uri = URI->new( $uri );
   }
   elsif( blessed $uri and !$uri->isa( "URI" ) ) {
      croak "Expected 'uri' as a URI reference";
   }

   my $method = delete $args{method} || "GET";

   $args{host} = $uri->host;
   $args{port} = $uri->port;

   my $request;

   if( $method eq "POST" ) {
      defined $args{content} or croak "Expected 'content' with POST method";

      # Lack of content_type didn't used to be a failure condition:
      ref $args{content} or defined $args{content_type} or
      carp "No 'content_type' was given with 'content'";

      # This will automatically encode a form for us
      $request = HTTP::Request::Common::POST( $uri, Content => $args{content}, Content_Type => $args{content_type} );
   }
   else {
      $request = HTTP::Request->new( $method, $uri );
   }

   $request->protocol( "HTTP/1.1" );
   $request->header( Host => $uri->host );

   my ( $user, $pass );

   if( defined $uri->userinfo ) {
      ( $user, $pass ) = split( m/:/, $uri->userinfo, 2 );
   }
   elsif( defined $args{user} and defined $args{pass} ) {
      $user = $args{user};
      $pass = $args{pass};
   }

   if( defined $user and defined $pass ) {
      $request->authorization_basic( $user, $pass );
   }

   $args{request} = $request;

   return %args;
}

=method C<GET>

  $ua->GET( $uri, %args ) ==> $response

=method C<HEAD>

 $ua->HEAD( $uri, %args ) ==> $response

=method C<POST>

 $ua->POST( $uri, $content, %args ) ==> $response

Convenient wrappers for using the C<GET>, C<HEAD> or C<POST> methods with a
C<URI> object and few if any other arguments, returning a C<Future>.

Please check the documentation of L</do_request> for the values you
can usefully pass in C<%args>.

=cut

sub GET {
   my ($self, $uri, @args) = @_;
   return $self->do_request( method => "GET", uri => $uri, @args );
}

sub HEAD {
   my ($self, $uri, @args) = @_;
   return $self->do_request( method => "HEAD", uri => $uri, @args );
}

sub POST {
   my ($self, $uri, $content, @args) = @_;
   return $self->do_request( method => "POST", uri => $uri, content => $content, @args );
}

1;
