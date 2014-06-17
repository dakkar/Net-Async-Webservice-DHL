package Net::Async::Webservice::Common::Types;
use strict;
use warnings;
use Type::Library
    -base,
    -declare => qw( AsyncUserAgent SyncUserAgent
                    HTTPRequest
              );
use Type::Utils -all;
use namespace::autoclean;

=head2 C<AsyncUserAgent>

Duck type, any object with a C<do_request>, C<GET> and C<POST>
methods.  Coerced from L</SyncUserAgent> via
L<Net::Async::Webservice::Common::SyncAgentWrapper>.

=head2 C<SyncUserAgent>

Duck type, any object with a C<request>, C<get> and C<post> methods.

=cut

duck_type AsyncUserAgent, [qw(GET POST do_request)];
duck_type SyncUserAgent, [qw(get post request)];

coerce AsyncUserAgent, from SyncUserAgent, via {
    require Net::Async::Webservice::Common::SyncAgentWrapper;
    Net::Async::Webservice::Common::SyncAgentWrapper->new({ua=>$_});
};

class_type HTTPRequest, { class => 'HTTP::Request' };

1;
