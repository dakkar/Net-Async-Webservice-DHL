package Net::Async::Webservice::DHL::Types;
$Net::Async::Webservice::DHL::Types::VERSION = '1.1.0';
{
  $Net::Async::Webservice::DHL::Types::DIST = 'Net-Async-Webservice-DHL';
}
use strict;
use warnings;
use Type::Library
    -base,
    -declare => qw( Address );
use Type::Utils -all;
use Types::Standard -types;
use namespace::autoclean;

# ABSTRACT: type library for DHL


class_type Address, { class => 'Net::Async::Webservice::DHL::Address' };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL::Types - type library for DHL

=head1 VERSION

version 1.1.0

=head1 DESCRIPTION

This L<Type::Library> declares a few type constraints and coercions
for use with L<Net::Async::Webservice::DHL>.

=head1 TYPES

=head2 C<Address>

Instance of L<Net::Async::Webservice::DHL::Address>.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
