package Net::Async::Webservice::DHL::Types;
$Net::Async::Webservice::DHL::Types::VERSION = '0.01_1';
{
  $Net::Async::Webservice::DHL::Types::DIST = 'Net-Async-Webservice-DHL';
}
use strict;
use warnings;
use Type::Library
    -base,
    -declare => qw( AsyncUserAgent
                    UserAgent
                    Address
              );
use Type::Utils -all;
use Types::Standard -types;
use namespace::autoclean;

# ABSTRACT: type library for DHL


class_type Address, { class => 'Net::Async::Webservice::DHL::Address' };


duck_type AsyncUserAgent, [qw(POST do_request)];
duck_type UserAgent, [qw(post request)];

coerce AsyncUserAgent, from UserAgent, via {
    require Net::Async::Webservice::DHL::SyncAgentWrapper;
    Net::Async::Webservice::DHL::SyncAgentWrapper->new({ua=>$_});
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL::Types - type library for DHL

=head1 VERSION

version 0.01_1

=head1 DESCRIPTION

This L<Type::Library> declares a few type constraints and coercions
for use with L<Net::Async::Webservice::DHL>.

=head1 TYPES

=head2 C<Address>

Instance of L<Net::Async::Webservice::DHL::Address>.

=head2 C<AsyncUserAgent>

Duck type, any object with a C<do_request> and C<POST> methods.
Coerced from L</UserAgent> via
L<Net::Async::Webservice::DHL::SyncAgentWrapper>.

=head2 C<UserAgent>

Duck type, any object with a C<request> and C<post> methods.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
