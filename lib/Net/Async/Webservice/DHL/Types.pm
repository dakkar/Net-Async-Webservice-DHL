package Net::Async::Webservice::DHL::Types;
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

=head1 DESCRIPTION

This L<Type::Library> declares a few type constraints and coercions
for use with L<Net::Async::Webservice::DHL>.

=head1 TYPES

=head2 C<Address>

Instance of L<Net::Async::Webservice::DHL::Address>.

=cut

class_type Address, { class => 'Net::Async::Webservice::DHL::Address' };

=head2 C<AsyncUserAgent>

Duck type, any object with a C<do_request> and C<POST> methods.
Coerced from L</UserAgent> via
L<Net::Async::Webservice::DHL::SyncAgentWrapper>.

=head2 C<UserAgent>

Duck type, any object with a C<request> and C<post> methods.

=cut

duck_type AsyncUserAgent, [qw(POST do_request)];
duck_type UserAgent, [qw(post request)];

coerce AsyncUserAgent, from UserAgent, via {
    require Net::Async::Webservice::DHL::SyncAgentWrapper;
    Net::Async::Webservice::DHL::SyncAgentWrapper->new({ua=>$_});
};

1;
