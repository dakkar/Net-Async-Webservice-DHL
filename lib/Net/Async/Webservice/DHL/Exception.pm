package Net::Async::Webservice::DHL::Exception;
use Moo;
with 'Throwable','StackTrace::Auto';
use overload
  q{""}    => 'as_string',
  fallback => 1;

=head1 NAME

Net::Async::Webservice::DHL::Exception - exception classes for DHL

=head1 DESCRIPTION

These classes are based on L<Throwable> and L<StackTrace::Auto>. The
L</as_string> method should return something readable, with a full
stack trace.

=head1 Classes

=head2 C<Net::Async::Webservice::DHL::Exception>

Base class.

=cut

around _build_stack_trace_args => sub {
    my ($orig,$self) = @_;

    my $ret = $self->$orig();
    push @$ret, (
        no_refs => 1,
        respect_overload => 1,
        message => '',
        indent => 1,
    );

    return $ret;
};

=head3 Methods

=head4 C<as_string>

Generic "something bad happened", with stack trace.

=cut

sub as_string { "something bad happened at ". $_[0]->stack_trace->as_string }

{package Net::Async::Webservice::DHL::Exception::ConfigError;
 use Moo;
 extends 'Net::Async::Webservice::DHL::Exception';

=head2 C<Net::Async::Webservice::DHL::Exception::ConfigError>

exception thrown when the configuration file can't be parsed

=head3 Attributes

=head4 C<file>

The name of the configuration file.

=cut

 has file => ( is => 'ro', required => 1 );

=head3 Methods

=head4 C<as_string>

Mentions the file name, and gives the stack trace.

=cut

 sub as_string {
     my ($self) = @_;

     return 'Bad config file: %s, at %s',
         $self->file,
         $self->stack_trace->as_string;
 }
}

{package Net::Async::Webservice::DHL::Exception::HTTPError;
 use Moo;
 extends 'Net::Async::Webservice::DHL::Exception';

=head2 C<Net::Async::Webservice::DHL::Exception::HTTPError>

exception thrown when the HTTP request fails

=head3 Attributes

=head4 C<request>

The request that failed.

=head4 C<response>

The failure response returned by the user agent

=cut

 has request => ( is => 'ro', required => 1 );
 has response => ( is => 'ro', required => 1 );

=head3 Methods

=head4 C<as_string>

Mentions the HTTP method, URL, response status line, and stack trace.

=cut

 sub as_string {
     my ($self) = @_;

     return sprintf 'Error %sing %s: %s, at %s',
         $self->request->method,$self->request->uri,
         $self->response->status_line,
         $self->stack_trace->as_string;
 }
}

{package Net::Async::Webservice::DHL::Exception::DHLError;
 use Moo;
 extends 'Net::Async::Webservice::DHL::Exception';

=head2 C<Net::Async::Webservice::DHL::Exception::DHLError>

exception thrown when DHL signals an error

=head3 Attributes

=head4 C<error>

The error data structure extracted from the DHL response.

=cut

 has error => ( is => 'ro', required => 1 );

=head3 Methods

=head4 C<as_string>

Mentions the description and code of the error, plus the stack trace.

=cut

 sub as_string {
     my ($self) = @_;

     my $c = $self->error->{Condition}[0];

     return sprintf 'DHL returned an error: %s, code %s, at %s',
         $c->{ConditionData}//'<undef>',
         $c->{ConditionCode}//'<undef>',
         $self->stack_trace->as_string;
 }
}

1;
