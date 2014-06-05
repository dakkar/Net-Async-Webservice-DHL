package Net::Async::Webservice::DHL::Exception;
$Net::Async::Webservice::DHL::Exception::VERSION = '0.01_1';
{
  $Net::Async::Webservice::DHL::Exception::DIST = 'Net-Async-Webservice-DHL';
}
use Moo;
with 'Throwable','StackTrace::Auto';
use overload
  q{""}    => 'as_string',
  fallback => 1;


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


sub as_string { "something bad happened at ". $_[0]->stack_trace->as_string }

{package Net::Async::Webservice::DHL::Exception::ConfigError;
$Net::Async::Webservice::DHL::Exception::ConfigError::VERSION = '0.01_1';
{
  $Net::Async::Webservice::DHL::Exception::ConfigError::DIST = 'Net-Async-Webservice-DHL';
}
 use Moo;
 extends 'Net::Async::Webservice::DHL::Exception';


 has file => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     return 'Bad config file: %s, at %s',
         $self->file,
         $self->stack_trace->as_string;
 }
}

{package Net::Async::Webservice::DHL::Exception::HTTPError;
$Net::Async::Webservice::DHL::Exception::HTTPError::VERSION = '0.01_1';
{
  $Net::Async::Webservice::DHL::Exception::HTTPError::DIST = 'Net-Async-Webservice-DHL';
}
 use Moo;
 extends 'Net::Async::Webservice::DHL::Exception';


 has request => ( is => 'ro', required => 1 );
 has response => ( is => 'ro', required => 1 );


 sub as_string {
     my ($self) = @_;

     return sprintf 'Error %sing %s: %s, at %s',
         $self->request->method,$self->request->uri,
         $self->response->status_line,
         $self->stack_trace->as_string;
 }
}

{package Net::Async::Webservice::DHL::Exception::DHLError;
$Net::Async::Webservice::DHL::Exception::DHLError::VERSION = '0.01_1';
{
  $Net::Async::Webservice::DHL::Exception::DHLError::DIST = 'Net-Async-Webservice-DHL';
}
 use Moo;
 extends 'Net::Async::Webservice::DHL::Exception';


 has error => ( is => 'ro', required => 1 );


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

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::Async::Webservice::DHL::Exception

=head1 VERSION

version 0.01_1

=head1 DESCRIPTION

These classes are based on L<Throwable> and L<StackTrace::Auto>. The
L</as_string> method should return something readable, with a full
stack trace.

=head1 NAME

Net::Async::Webservice::DHL::Exception - exception classes for DHL

=head1 Classes

=head2 C<Net::Async::Webservice::DHL::Exception>

Base class.

=head3 Methods

=head4 C<as_string>

Generic "something bad happened", with stack trace.

=head2 C<Net::Async::Webservice::DHL::Exception::ConfigError>

exception thrown when the configuration file can't be parsed

=head3 Attributes

=head4 C<file>

The name of the configuration file.

=head3 Methods

=head4 C<as_string>

Mentions the file name, and gives the stack trace.

=head2 C<Net::Async::Webservice::DHL::Exception::HTTPError>

exception thrown when the HTTP request fails

=head3 Attributes

=head4 C<request>

The request that failed.

=head4 C<response>

The failure response returned by the user agent

=head3 Methods

=head4 C<as_string>

Mentions the HTTP method, URL, response status line, and stack trace.

=head2 C<Net::Async::Webservice::DHL::Exception::DHLError>

exception thrown when DHL signals an error

=head3 Attributes

=head4 C<error>

The error data structure extracted from the DHL response.

=head3 Methods

=head4 C<as_string>

Mentions the description and code of the error, plus the stack trace.

=head1 AUTHOR

Gianni Ceccarelli <gianni.ceccarelli@net-a-porter.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Net-a-porter.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
