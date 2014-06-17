package Net::Async::Webservice::Common::WithConfigFile;
use Moo::Role;
use Net::Async::Webservice::Common::Exception;
use namespace::autoclean;
use 5.010;

# ABSTRACT: automatically load constructor args from a config file

=head1 SEE ALSO

L<MooX::ConfigFromFile> for a more comprehensive solution.

=cut

around BUILDARGS => sub {
    my ($orig,$class,@args) = @_;

    my $ret = $class->$orig(@args);

    if (my $config_file = delete $ret->{config_file}) {
        $ret = {
            %{_load_config_file($config_file)},
            %$ret,
        };
    }

    return $ret;
};

sub _load_config_file {
    my ($file) = @_;
    require Config::Any;
    my $loaded = Config::Any->load_files({
        files => [$file],
        use_ext => 1,
        flatten_to_hash => 1,
    });
    my $config = $loaded->{$file};
    Net::Async::Webservice::Common::Exception::ConfigError->throw({
        file => $file,
    }) unless $config;
    return $config;
}

1;
