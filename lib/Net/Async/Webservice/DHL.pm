package Net::Async::Webservice::DHL;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str Bool Object Dict Num Optional ArrayRef HashRef Undef);
use Net::Async::Webservice::DHL::Types qw(AsyncUserAgent Address);
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
use 5.10.0;

# ABSTRACT: DHL API client

my %base_urls = (
    live => 'https://xmlpi-ea.dhl.com/XMLShippingServlet',
    test => 'https://xmlpitest-ea.dhl.com/XMLShippingServlet',
);
sub _base_urls { return {%base_urls} }

has live_mode => (
    is => 'rw',
    isa => Bool,
    trigger => 1,
    default => sub { 0 },
);

has base_url_test => (
    is => 'ro',
    isa => Str,
    default => sub { $base_urls{test} },
);

has base_url_live => (
    is => 'ro',
    isa => Str,
    default => sub { $base_urls{live} },
);

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

    my $attr = 'base_url_'.($self->live_mode ? 'live' : 'test');
    return $self->$attr;
}

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

has user_agent => (
    is => 'ro',
    isa => AsyncUserAgent,
    required => 1,
);

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

around BUILDARGS => sub {
    my ($orig,$class,@args) = @_;

    my $ret = $class->$orig(@args);

    if (my $config_file = delete $ret->{config_file}) {
        $ret = {
            %{_load_config_file($config_file)},
            %$ret,
        };
    }

    if (ref $ret->{loop} && !$ret->{user_agent}) {
        require Net::Async::HTTP;
        $ret->{user_agent} = Net::Async::HTTP->new();
        $ret->{loop}->add($ret->{user_agent});
    }

    return $ret;
};

sub _load_config_file {
    my ($file) = @_;
    require Config::Any;
    my $loaded = Config::Any->load_files({
        files => [$file],
        use_ext => 1,
        flatten_to_hash => 1,
    });
    my $config = $loaded->{$file};
    Net::Async::Webservice::DHL::Exception::ConfigError->throw({
        file => $file,
    }) unless $config;
    return $config;
}

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
        ],
    );
    my ($self,$args) = $argcheck->(@_);

    my $now = DateTime->now(time_zone => 'UTC');

    my $req = {
        From => $args->{from}->as_hash,
        To => $args->{to}->as_hash,
        BkgDetails => {
            PaymentCountryCode => $args->{to}->country_code,
            Date => $now->ymd,
            ReadyTime => 'PT' . $now->hour . 'H' . $now->minute . 'M',
            DimensionUnit => 'CM',
            WeightUnit => 'KG',
            IsDutiable => ($args->{is_dutiable} ? 'Y' : 'N'),
            NetworkTypeCode => 'AL',
            QtdShp => {
                GlobalProductCode => $args->{product_code},
                QtdShpExChrg => {
                    SpecialServiceType => 'OSINFO',
                },
            },
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

sub xml_request {
    state $argcheck = compile(
        Object,
        Dict[
            data => HashRef,
            request_method => Str,
            message_time => Optional[Str],
        ],
    );
    my ($self, $args) = $argcheck->(@_);

    my $now = DateTime->now(time_zone => 'UTC');

    my $doc = XML::LibXML::Document->new('1.0','utf-8');

    my $writer = $self->_xml_cache->writer('{http://www.dhl.com}DCTRequest');

    my $req = {
        $args->{request_method} => {
            Request => {
                ServiceHeader => {
                    MessageTime => ($args->{message_time} // $now->iso8601),
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

    ::note $request;

    return $self->post( $request )->then(
        sub {
            my ($response_string) = @_;

            if ($response_string =~ m{<\w+:DCTResponse\b}) {
                return Future->wrap($response_string);
            }
            else {
                return Future->new->fail($response_string);
            }
        }
    )->then(
        sub {
            my ($response_string) = @_;

            my $reader = $self->_xml_cache->reader('{http://www.dhl.com}DCTResponse');

            my $response = $reader->($response_string);

            return Future->wrap($response);
        }
    )->else(
        sub {
            my ($response_string) = @_;

            my $reader = $self->_xml_cache->reader('{http://www.dhl.com}ErrorResponse');
            my $response = $reader->($response_string);

            return Future->new->fail(
                Net::Async::Webservice::DHL::Exception::DHLError->new({
                    error => $response->{Response}{Status}
                }),
            );
        }
    );
}

sub post {
    state $argcheck = compile( Object, Str );
    my ($self, $body) = $argcheck->(@_);

    my $request = HTTP::Request->new(
        POST => $self->base_url,
        [], encode('utf-8',$body),
    );
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
            my ($exception,undef,$response,$request) = @_;
            return Net::Async::Webservice::UPS::Exception::HTTPError->new({
                request=>$request,
                response=>$response,
            })
        },
    );
}

=head1 SYNOPSIS

  use Net::Async::Webservice::DHL;

=head1 DESCRIPTION

=cut

1;
