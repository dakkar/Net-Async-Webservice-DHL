package Net::Async::Webservice::DHL::SyncAgentWrapper;
$Net::Async::Webservice::DHL::SyncAgentWrapper::VERSION = '0.01_2';
{
  $Net::Async::Webservice::DHL::SyncAgentWrapper::DIST = 'Net-Async-Webservice-DHL';
}
use Moo;
use Net::Async::Webservice::DHL::Types 'UserAgent';
use namespace::autoclean;

# ABSTRACT: minimal wrapper to adapt a sync UA


has ua => (
    is => 'ro',
    isa => UserAgent,
    required => 1,
);


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


sub POST { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL::SyncAgentWrapper - minimal wrapper to adapt a sync UA

=head1 VERSION

version 0.01_2

=head1 DESCRIPTION

An instance of this class will be automatically created if you pass a
L<LWP::UserAgent> (or something that looks like it) to the constructor
for L<Net::Async::Webservice::DHL>. You should probably not care about
it.

=head1 ATTRIBUTES

=head2 C<ua>

The actual user agent instance.

=head1 METHODS

=head2 C<do_request>

Delegates to C<< $self->ua->request >>, and returns an immediate
L<Future>.

=head2 C<POST>

Empty method, here just to help with duck-type detection.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
