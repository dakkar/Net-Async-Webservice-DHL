package Net::Async::Webservice::DHL::Address;
use Moo;
use 5.10.0;
use Types::Standard qw(Str Int Bool StrictNum);
use Net::Async::Webservice::DHL::Types ':types';

# ABSTRACT: an address for DHL

=attr C<city>

String with the name of the city, optional.

=cut

has city => (
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
    isa => Str,
    required => 1,
);

=method C<as_hash>

Returns a hashref that, when passed through L<XML::Compile>, will
produce the XML fragment needed in DHL requests to represent this
address.

=cut

sub as_hash {
    my ($self) = @_;

    return {
        CountryCode => (
            $self->country_code,
        ),
        ($self->postal_code ?
             (Postalcode => (
                 $self->postal_code,
             )) : () ),
        ($self->city ?
             (City => (
                 $self->city,
             )) : () ),
    };
}

1;
