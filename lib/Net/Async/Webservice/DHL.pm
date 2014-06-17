package Net::Async::Webservice::DHL;
use Moo;
use Types::Standard qw(Str Bool Object Dict Num Optional ArrayRef HashRef Undef Optional);
use Types::URI qw(Uri);
use Types::DateTime
    DateTime => { -as => 'DateTimeT' },
    Format => { -as => 'DTFormat' };
use Net::Async::Webservice::DHL::Types qw(Address);
use Net::Async::Webservice::DHL::Exception;
use Type::Params qw(compile);
use Error::TypeTiny;
use Try::Tiny;
use List::AllUtils 'pairwise';
use HTTP::Request;
use XML::Compile::Cache;
use XML::LibXML;
use Encode;
use namespace::autoclean;
use Future;
use DateTime;
use File::ShareDir::ProjectDistDir 'dist_dir', strict => 1;
use 5.010;

# ABSTRACT: DHL API client, non-blocking

=head1 SYNOPSIS

 use IO::Async::Loop;
 use Net::Async::Webservice::DHL;
 use Data::Printer;

 my $loop = IO::Async::Loop->new;

 my $dhl = Net::Async::Webservice::DHL->new({
   config_file => $ENV{HOME}.'/.naws_dhl.conf',
   loop => $loop,
 });

 $dhl->get_capability({
   from => $address_a,
   to => $address_b,
   is_dutiable => 0,
   product_code => 'N',
   currency_code => 'GBP',
   shipment_value => 100,
 })->then(sub {
   my ($response) = @_;
   p $response;
   return Future->wrap();
 });

 $loop->run;

Alternatively:

 use Net::Async::Webservice::DHL;
 use Data::Printer;

 my $ups = Net::Async::Webservice::DHL->new({
   config_file => $ENV{HOME}.'/.naws_dhl.conf',
   user_agent => LWP::UserAgent->new,
 });

 my $response = $dhl->get_capability({
   from => $address_a,
   to => $address_b,
   is_dutiable => 0,
   product_code => 'N',
   currency_code => 'GBP',
   shipment_value => 100,
 })->get;

 p $response;

=head1 DESCRIPTION

This class implements some of the methods of the DHL XML-PI API, using
L<Net::Async::HTTP> as a user agent I<by default> (you can still pass
something like L<LWP::UserAgent> and it will work). All methods that
perform API calls return L<Future>s (if using a synchronous user
agent, all the Futures will be returned already completed).

=cut

my %base_urls = (
    live => 'https://xmlpi-ea.dhl.com/XMLShippingServlet',
    test => 'https://xmlpitest-ea.dhl.com/XMLShippingServlet',
);

=attr C<live_mode>

Boolean, defaults to false. When set to true, the live API endpoint
will be used, otherwise the test one will. Flipping this attribute
will reset L</base_url>, so you generally don't want to touch this if
you're using some custom API endpoint.

=cut

has live_mode => (
    is => 'rw',
    isa => Bool,
    trigger => 1,
    default => sub { 0 },
);

=attr C<base_url>

A L<URI> object, coercible from a string. The base URL to use to send
API requests to. Defaults to the standard DHL endpoints:

=for :list
* C<https://xmlpi-ea.dhl.com/XMLShippingServlet> for live
* C<https://xmlpitest-ea.dhl.com/XMLShippingServlet> for testing

See also L</live_mode>.

=cut

has base_url => (
    is => 'lazy',
    isa => Str,
    clearer => '_clear_base_url',
);

sub _trigger_live_mode {
    my ($self) = @_;

    $self->_clear_base_url;
}
sub _build_base_url {
    my ($self) = @_;

    return $base_urls{$self->live_mode ? 'live' : 'test'};
}

=attr C<username>

=attr C<password>

Strings, required. Authentication credentials.

=cut

has username => (
    is => 'ro',
    isa => Str,
    required => 1,
);
has password => (
    is => 'ro',
    isa => Str,
    required => 1,
);

=attr C<user_agent>

A user agent object, looking either like L<Net::Async::HTTP> (has
C<do_request> and C<POST>) or like L<LWP::UserAgent> (has C<request>
and C<post>). You can pass the C<loop> constructor parameter to get a
default L<Net::Async::HTTP> instance.

=cut

with 'Net::Async::Webservice::Common::WithUserAgent';

has _xml_cache => (
    is => 'lazy',
);

sub _build__xml_cache {
    my ($self) = @_;

    my $dir = dist_dir('Net-Async-Webservice-DHL');
    my $c = XML::Compile::Cache->new(
        schema_dirs => [ $dir ],
        opts_rw => {
            elements_qualified => 'TOP',
        },
    );
    for my $f (qw(datatypes DCT-req DCT-Response DCTRequestdatatypes DCTResponsedatatypes err-res)) {
        $c->importDefinitions("$f.xsd");
    }
    $c->declare('WRITER' => '{http://www.dhl.com}DCTRequest');
    $c->declare('READER' => '{http://www.dhl.com}DCTResponse');
    $c->declare('READER' => '{http://www.dhl.com}ErrorResponse');
    $c->compileAll;

    return $c;
}

=method C<new>

Async:

  my $dhl = Net::Async::Webservice::DHL->new({
     loop => $loop,
     config_file => $file_name,
  });

Sync:

  my $dhl = Net::Async::Webservice::DHL->new({
     user_agent => LWP::UserAgent->new,
     config_file => $file_name,
  });

In addition to passing all the various attributes values, you can use
a few shortcuts.

=for :list
= C<loop>
a L<IO::Async::Loop>; a locally-constructed L<Net::Async::HTTP> will be registered to it and set as L</user_agent>
= C<config_file>
a path name; will be parsed with L<Config::Any>, and the values used as if they had been passed in to the constructor

=for Pod::Coverage
BUILDARGS

=cut

with 'Net::Async::Webservice::Common::WithConfigFile';

=method C<get_capability>

 $dhl->get_capability({
   from => $address_a,
   to => $address_b,
   is_dutiable => 0,
   product_code => 'N',
   currency_code => 'GBP',
   shipment_value => 100,
 }) ==> ($hashref)

C<from> and C<to> are instances of
L<Net::Async::Webservice::DHL::Address>, C<is_dutiable> is a boolean,
C<product_code> is a DHL product code.

Optional parameters:

=for :list
= C<date>
the date/time for the booking, defaults to I<now>; it will converted to UTC time zone

Performs a C<GetCapability> request. Lots of values in the request are
not filled in, this should be used essentially to check for address
validity and little more. I'm not sure how to read the response,
either.

The L<Future> returned will yield a hashref containing the
"interesting" bits of the XML response (as judged by
L<XML::Compile::Schema>), or fail with an exception.

=cut

sub get_capability {
    state $argcheck = compile(
        Object,
        Dict[
            from => Address,
            to => Address,
            is_dutiable => Bool,
            product_code => Str,
            currency_code => Str,
            shipment_value => Num,
            date => Optional[DateTimeT->plus_coercions(DTFormat['ISO8601'])],
        ],
    );
    my ($self,$args) = $argcheck->(@_);

    $args->{date} = $args->{date}
        ? $args->{date}->clone->set_time_zone('UTC')
        : DateTime->now(time_zone => 'UTC');

    my $req = {
        From => $args->{from}->as_hash,
        To => $args->{to}->as_hash,
        BkgDetails => {
            PaymentCountryCode => $args->{to}->country_code,
            Date => $args->{date}->ymd,
            ReadyTime => 'PT' . $args->{date}->hour . 'H' . $args->{date}->minute . 'M',
            DimensionUnit => 'CM',
            WeightUnit => 'KG',
            IsDutiable => ($args->{is_dutiable} ? 'Y' : 'N'),
            NetworkTypeCode => 'AL',
        },
        Dutiable => {
            DeclaredCurrency => $args->{currency_code},
            DeclaredValue => $args->{shipment_value},
        },
    };

    return $self->xml_request({
        data => $req,
        request_method => 'GetCapability',
    })->then(
        sub {
            my ($response) = @_;
            return Future->wrap($response);
        },
    );
}

=method C<xml_request>

  $dhl->xml_request({
    request_method => $string,
    data => \%request_data,
  }) ==> ($parsed_response);

This method is mostly internal, you shouldn't need to call it.

It builds a request XML document by passing the given C<data> to an
L<XML::Compile> writer built on the DHL C<DCTRequest> schema.

It then posts (possibly asynchronously) this to the L</base_url> (see
the L</post> method). If the request is successful, it parses the body
with a L<XML::Compile> reader, either the one for C<DCTResponse> or
the one for C<ErrorResponse>, depending on the document element. If
it's C<DCTResponse>, the Future is completed with the hashref returned
by the reader. If it's C<ErrorResponse>, teh Future is failed with a
L<Net::Async::Webservice::DHL::Exception::DHLError> contaning the
response status.

=cut

sub xml_request {
    state $argcheck = compile(
        Object,
        Dict[
            data => HashRef,
            request_method => Str,
            message_time => Optional[DateTimeT->plus_coercions(DTFormat['ISO8601'])],
        ],
    );
    my ($self, $args) = $argcheck->(@_);

    $args->{message_time} = $args->{message_time}
        ? $args->{message_time}->clone->set_time_zone('UTC')
        : DateTime->now(time_zone => 'UTC');

    my $doc = XML::LibXML::Document->new('1.0','utf-8');

    my $writer = $self->_xml_cache->writer('{http://www.dhl.com}DCTRequest');

    my $req = {
        $args->{request_method} => {
            Request => {
                ServiceHeader => {
                    MessageTime => $args->{message_time}->iso8601,
                    SiteID => $self->username,
                    Password => $self->password,
                },
            },
            %{$args->{data}},
        },
    };

    my $docElem = $writer->($doc,$req);
    $doc->setDocumentElement($docElem);

    my $request = $doc->toString(1);

    return $self->post( $self->base_url, $request )->then(
        sub {
            my ($response_string) = @_;

            my $response_doc = XML::LibXML->load_xml(
                string=>\$response_string,
                load_ext_dtd => 0,
                expand_xincludes => 0,
                no_network => 1,
            );

            if ($response_doc->documentElement->nodeName =~ /:DCTResponse$/) {
                my $reader = $self->_xml_cache->reader('{http://www.dhl.com}DCTResponse');
                my $response = $reader->($response_doc);
                return Future->wrap($response);
            }
            else {
                my $reader = $self->_xml_cache->reader('{http://www.dhl.com}ErrorResponse');
                my $response = $reader->($response_doc);
                return Future->new->fail(
                    Net::Async::Webservice::DHL::Exception::DHLError->new({
                        error => $response->{Response}{Status}
                    }),
                    'dhl',
                );
            }
        }
    );
}

=method C<post>

  $dhl->post($body) ==> ($decoded_content)

Posts the given C<$body> to the L</base_url>. If the request is
successful, it completes the returned future with the decoded content
of the response, otherwise it fails the future with a
L<Net::Async::Webservice::Common::Exception::HTTPError> instance.

=cut

with 'Net::Async::Webservice::Common::WithRequestWrapper';

1;
