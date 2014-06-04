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

duck_type AsyncUserAgent, [qw(POST do_request)];
duck_type UserAgent, [qw(post request)];

coerce AsyncUserAgent, from UserAgent, via {
    require Net::Async::Webservice::DHL::SyncAgentWrapper;
    Net::Async::Webservice::DHL::SyncAgentWrapper->new({ua=>$_});
};

class_type Address, { class => 'Net::Async::Webservice::DHL::Address' };

1;
