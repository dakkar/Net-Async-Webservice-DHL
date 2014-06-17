package Net::Async::Webservice::Common::WithUserAgent;
use Moo::Role;
use Net::Async::Webservice::Common::Types qw(AsyncUserAgent);
use namespace::autoclean;
use 5.010;

# ABSTRACT: user_agent attribute, sync or async

has user_agent => (
    is => 'ro',
    isa => AsyncUserAgent,
    required => 1,
    coerce => AsyncUserAgent->coercion,
);

around BUILDARGS => sub {
    my ($orig,$class,@args) = @_;

    my $ret = $class->$orig(@args);

    if (ref $ret->{loop} && !$ret->{user_agent}) {
        require Net::Async::HTTP;
        $ret->{user_agent} = Net::Async::HTTP->new();
        $ret->{loop}->add($ret->{user_agent});
    }

    return $ret;
};

1;
