package Net::Async::Webservice::Common::WithRequestWrapper;
use Moo::Role;
use Types::Standard qw(Object HashRef Str);
use Types::URI qw(Uri);
use Type::Params qw(compile);
use Net::Async::Webservice::Common::Types qw(HTTPRequest);
use Net::Async::Webservice::Common::Exception;
use HTTP::Request;
use Encode;
use namespace::autoclean;
use 5.010;

requires 'user_agent';

has ssl_options => (
    is => 'lazy',
    isa => HashRef,
);
sub _build_ssl_options {
    # this is to work around an issue with IO::Async::SSL, see
    # https://rt.cpan.org/Ticket/Display.html?id=96474
    eval "require IO::Socket::SSL" or return {};
    return { SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_PEER() }
}

sub request {
    state $argcheck = compile( Object, HTTPRequest );
    my ($self, $request) = $argcheck->(@_);

    my $response_future = $self->user_agent->do_request(
        request => $request,
        fail_on_error => 1,
    )->transform(
        done => sub {
            my ($response) = @_;
            return $response->decoded_content(
                default_charset => 'utf-8',
                raise_error => 1,
            )
        },
        fail => sub {
            my ($exception,$kind,$response,$req2) = @_;
            return (Net::Async::Webservice::Common::Exception::HTTPError->new({
                request=>($req2//$request),
                response=>$response,
                (($kind//'') ne 'http' ? ( more_info => "@_" ) : ()),
            }),'webservice');
        },
    );
}

sub post {
    state $argcheck = compile( Object, Uri, Str );
    my ($self, $url, $body) = $argcheck->(@_);

    my $request = HTTP::Request->new(
        POST => $url,
        [], encode('utf-8',$body),
    );
    return $self->request($request);
}

sub get {
    state $argcheck = compile( Object, Uri );
    my ($self, $url) = $argcheck->(@_);

    my $request = HTTP::Request->new(
        GET => $url,
    );
    return $self->request($request);
}

1;
