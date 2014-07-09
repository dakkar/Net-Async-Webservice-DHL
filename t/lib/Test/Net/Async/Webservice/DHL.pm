package Test::Net::Async::Webservice::DHL;
use strict;
use warnings;
use Test::Most;
use Data::Printer;
use Net::Async::Webservice::DHL::Address;

sub conf_file {
    my $dhlrc = $ENV{NAWS_DHL_CONFIG} || File::Spec->catfile($ENV{HOME}, '.naws_dhl.conf');
    if (not -r $dhlrc) {
        plan(skip_all=>'need a ~/.naws_dhl.conf file, or a NAWS_DHL_CONFIG env variable pointing to a valid config file');
        exit(0);
    }
    return $dhlrc;
}

sub test_it {
    my ($dhl) = @_;

    subtest 'setting live / testing' => sub {
        is($dhl->live_mode,0,'starts in testing');
        my $test_url = $dhl->base_url;

        $dhl->live_mode(1);
        is($dhl->live_mode,1,'can be set live');
        isnt($dhl->base_url,$test_url,'live proxy different than test one');

        $dhl->live_mode(0);
        is($dhl->live_mode,0,'can be set back to testing');
        is($dhl->base_url,$test_url,'test proxy same as before');
    };

    subtest 'address validation' => sub {
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
                                Srv => superbagof(
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

        $dhl->get_capability({
            from => $from,
            to => $to,
            is_dutiable => 0,
            product_code => 'C',
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
                                Srv => [
                                    superhashof({
                                        GlobalProductCode => 'C',
                                        MrkSrv => ignore(),
                                    }),
                                ],
                            },
                        },
                    },
                    'response with product_code is shaped ok',
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
}

1;
