package Net::Async::Webservice::DHL::Address;
$Net::Async::Webservice::DHL::Address::VERSION = '0.01_6';
{
  $Net::Async::Webservice::DHL::Address::DIST = 'Net-Async-Webservice-DHL';
}
use Moo;
use 5.010;
use Types::Standard qw(Str Int Bool StrictNum);
use Net::Async::Webservice::DHL::Types ':types';

# ABSTRACT: an address for DHL


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

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL::Address - an address for DHL

=head1 VERSION

version 0.01_6

=head1 ATTRIBUTES

=head2 C<city>

String with the name of the city, optional.

=head2 C<postal_code>

String with the post code of the address, optional.

=head2 C<country_code>

String with the 2 letter country code, required.

=head1 METHODS

=head2 C<as_hash>

Returns a hashref that, when passed through L<XML::Compile>, will
produce the XML fragment needed in DHL requests to represent this
address.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
