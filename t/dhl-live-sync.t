#!perl
use strict;
use warnings;
use Test::Most;
use lib 't/lib';
use Test::Net::Async::Webservice::DHL;
use Test::Net::Async::Webservice::DHL::Factory;

my ($dhl,$loop) = Test::Net::Async::Webservice::DHL::Factory::from_config_sync;

Test::Net::Async::Webservice::DHL::test_it($dhl);

done_testing();
