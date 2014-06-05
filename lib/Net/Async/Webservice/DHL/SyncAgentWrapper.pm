package Net::Async::Webservice::DHL::SyncAgentWrapper;
use Moo;
use Net::Async::Webservice::DHL::Types 'UserAgent';
use namespace::autoclean;

# ABSTRACT: minimal wrapper to adapt a sync UA

=head1 DESCRIPTION

An instance of this class will be automatically created if you pass a
L<LWP::UserAgent> (or something that looks like it) to the constructor
for L<Net::Async::Webservice::DHL>. You should probably not care about
it.

=attr C<ua>

The actual user agent instance.

=cut

has ua => (
    is => 'ro',
    isa => UserAgent,
    required => 1,
);

=method C<do_request>

Delegates to C<< $self->ua->request >>, and returns an immediate
L<Future>.

=cut

sub do_request {
    my ($self,%args) = @_;

    my $request = $args{request};
    my $fail = $args{fail_on_error};

    my $response = $self->ua->request($request);
    if ($fail && ! $response->is_success) {
        return Future->new->fail($response->status_line,'http',$response,$request);
    }
    return Future->wrap($response);
}

=method C<POST>

Empty method, here just to help with duck-type detection.

=cut

sub POST { }

1;
