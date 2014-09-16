package Net::Async::Webservice::DHL::Types;
use strict;
use warnings;
use Type::Library
    -base,
    -declare => qw( Address RouteType CountryCode RegionCode );
use Type::Utils -all;
use Types::Standard -types;
use namespace::autoclean;

# ABSTRACT: type library for DHL

=head1 DESCRIPTION

This L<Type::Library> declares a few type constraints and coercions
for use with L<Net::Async::Webservice::DHL>.

=head1 TYPES

=head2 C<Address>

Instance of L<Net::Async::Webservice::DHL::Address>.

=cut

class_type Address, { class => 'Net::Async::Webservice::DHL::Address' };

enum RouteType, [qw(O D)];

declare CountryCode, as Str, where { length($_) == 2 };

enum RegionCode, [qw(AP EU AM)];

1;
