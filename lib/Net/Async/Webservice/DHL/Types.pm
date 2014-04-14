package Net::Async::Webservice::DHL::Types;
use strict;
use warnings;
use Type::Library
    -base,
    -declare => qw( AsyncUserAgent
                    Address
              );
use Type::Utils -all;
use Types::Standard -types;
use namespace::autoclean;

duck_type AsyncUserAgent, [qw(POST do_request)];
class_type Address, { class => 'Net::Async::Webservice::DHL::Address' };

1;
