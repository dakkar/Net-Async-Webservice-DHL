package Net::Async::Webservice::DHL::Address;
use Moo;
use 5.010;
use Types::Standard qw(Str Int Bool StrictNum);
use Net::Async::Webservice::DHL::Types ':types';

# ABSTRACT: an address for DHL

=attr C<line1>

=attr C<line2>

=attr C<line3>

Address lines, all optional strings.

=cut

for my $l (1..3) {
    has "line$l" => (
        is => 'ro',
        isa => Str,
        required => 0,
    );
}

=attr C<city>

String with the name of the city, optional.

=cut

has city => (
    is => 'ro',
    isa => Str,
    required => 0,
);

=attr C<division>

Code of the division (e.g. state, prefecture, etc.), optional string.

=cut

has division => (
    is => 'ro',
    isa => Str,
    required => 0,
);

=attr C<postal_code>

String with the post code of the address, optional.

=cut

has postal_code => (
    is => 'ro',
    isa => Str,
    required => 0,
);

=attr C<country_code>

String with the 2 letter country code, required.

=cut

has country_code => (
    is => 'ro',
    isa => CountryCode,
    required => 1,
);

=attr C<country_name>

String with the full country name, required only for some uses.

=cut

has country_name => (
    is => 'ro',
    isa => Str,
    required => 0,
);

=method C<as_hash>

Returns a hashref that, when passed through L<XML::Compile>, will
produce the XML fragment needed in DHL requests to represent this
address.

=cut

{
our $_self;
sub _if {
    my ($method,$key) = @_;
    if ($_self->$method) {
        return ( $key => $_self->$method );
    }
    return;
};

sub as_hash {
    my ($self,$shape) = @_;
    local $_self=$self;

    if ($shape eq 'capability') {
        return {
            _if(postal_code => 'Postalcode'),
            _if(city => 'City'),
            CountryCode => $self->country_code,
        };
    }
    elsif ($shape eq 'route') {
        return {
            _if(line1 => 'Address1'),
            _if(line2 => 'Address2'),
            _if(line3 => 'Address3'),
            _if(postal_code => 'PostalCode'),
            _if(city => 'City'),
            _if(division => 'Division'),
            CountryCode => $self->country_code,
            CountryName => '', # the value is required, but an empty
                               # string will do
            _if(country_name => 'CountryName'),
        };
    };
}
}

1;
