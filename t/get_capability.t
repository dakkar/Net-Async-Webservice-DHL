#!perl
use strict;
use warnings;
use Test::Most;
use Net::Async::Webservice::DHL;
use Net::Async::Webservice::DHL::Address;
use IO::Async::Loop;
use Data::Printer;
use Future;
#use Log::Report mode => 'DEBUG';

# you need a ~/.dhlrc.conf file with two lines like:
#
#  username TestUserName
#  password TestPassWord
#
# of course use actual values instead of TestUserName / TestPassWord
my $dhlrc = File::Spec->catfile($ENV{HOME}, '.dhlrc.conf');
if (not -r $dhlrc) {
    plan(skip_all=>$_);
    exit(0);
}

my $loop = IO::Async::Loop->new;

my $dhl = Net::Async::Webservice::DHL->new({
    loop => $loop,
    config_file => $dhlrc,
});

# debug: print out everything that the XML::Compile::Schema knows
# $dhl->_xml_cache->printIndex;

subtest 'simple' => sub {
    my $from = Net::Async::Webservice::DHL::Address->new({
        country_code => 'GB',
        postal_code => 'SE7 7RU',
        city => 'London',
    });
    my $to = Net::Async::Webservice::DHL::Address->new({
        country_code => 'GB',
        postal_code => 'BN1 9RF',
        city => 'London',
    });

    $dhl->get_capability({
        from => $from,
        to => $to,
        is_dutiable => 0,
        product_code => 'N',
        currency_code => 'GBP',
        shipment_value => 100,
    })->then(
        sub {
            my ($response) = @_;
            note p $response;
            cmp_deeply(
                $response,
                {
                    GetCapabilityResponse => {
                        BkgDetails => [{
                            DestinationServiceArea => {
                                FacilityCode    => "LGW",
                                ServiceAreaCode => "LGW"
                            },
                            OriginServiceArea      => {
                                FacilityCode    => "LCY",
                                ServiceAreaCode => "LCY"
                            },
                            QtdShp => ignore(),
                        }],
                        Response => ignore(),
                        Srvs => {
                            Srv => bag(
                                {
                                    GlobalProductCode => 'N',
                                    MrkSrv => ignore(),
                                },
                                {
                                    GlobalProductCode => 'C',
                                    MrkSrv => ignore(),
                                },
                                {
                                    GlobalProductCode => '1',
                                    MrkSrv => ignore(),
                                },
                            ),
                        },
                    },
                },
                'response is shaped ok',
            );
            return Future->wrap();
        }
    )->get;
};

subtest 'bad address' => sub {
    my $from = Net::Async::Webservice::DHL::Address->new({
        country_code => 'GB',
        postal_code => 'SE7 7RU',
        city => 'London',
    });
    my $to = Net::Async::Webservice::DHL::Address->new({
        country_code => 'GB',
        postal_code => 'XX7 6YY',
        city => 'London',
    });

    $dhl->get_capability({
        from => $from,
        to => $to,
        is_dutiable => 0,
        product_code => 'N',
        currency_code => 'GBP',
        shipment_value => 100,
    })->then(
        sub {
            my ($response) = @_;
            note p $response;
            cmp_deeply(
                $response,
                {
                    GetCapabilityResponse => {
                        Note => [{
                            Condition => [{
                                ConditionCode => 3006,
                                ConditionData => ignore(),
                            }],
                        }],
                        Response => ignore(),
                    },
                },
                'response signals address failure',
            );
            return Future->wrap();
        }
    )->get;
};

subtest 'parse failure response' => sub {
    my $xml = <<'XML';
<?xml version="1.0" encoding="UTF-8"?><res:ErrorResponse xmlns:res='http://www.dhl.com' xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' xsi:schemaLocation= 'http://www.dhl.com err-res.xsd'>
     <Response>
         <ServiceHeader>
             <MessageTime>2014-04-14T15:43:57+01:00</MessageTime>
             <SiteID>CIMGBTest</SiteID>
             <Password>CIMGBTest</Password>
         </ServiceHeader>
         <Status>
             <ActionStatus>Error</ActionStatus>
             <Condition>
                 <ConditionCode>111</ConditionCode>
                 <ConditionData>Error in parsing request XML:Error:
                     Datatype error: In element
                     &apos;GlobalProductCode&apos; : Value &apos;&apos;
                     does not match regular expression facet
                     &apos;[A-Z0-9]+&apos;.. at line 26, column 57</ConditionData>
             </Condition>
         </Status>
     </Response></res:ErrorResponse>
XML
    my $reader = $dhl->_xml_cache->reader('{http://www.dhl.com}ErrorResponse');
    my $data = $reader->($xml);

    cmp_deeply(
        $data,
        {
            Response => superhashof({
                Status => {
                    ActionStatus => 'Error',
                    Condition => [
                        {
                            ConditionCode => 111,
                            ConditionData => ignore(),
                        },
                    ],
                },
            }),
        },
        'error response parsed correctly',
    );
};

done_testing;

