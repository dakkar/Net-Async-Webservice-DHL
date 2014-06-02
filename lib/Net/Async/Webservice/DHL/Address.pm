package Net::Async::Webservice::DHL::Address;
use strict;
use warnings;
use Moo;
use 5.10.0;
use Types::Standard qw(Str Int Bool StrictNum);
use Net::Async::Webservice::DHL::Types ':types';

has city => (
    is => 'ro',
    isa => Str,
    required => 0,
);

has postal_code => (
    is => 'ro',
    isa => Str,
    required => 0,
);

has country_code => (
    is => 'ro',
    isa => Str,
    required => 1,
);

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
