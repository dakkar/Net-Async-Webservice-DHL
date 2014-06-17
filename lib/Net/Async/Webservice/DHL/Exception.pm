package Net::Async::Webservice::DHL::Exception;
use strict;

=head1 NAME

Net::Async::Webservice::DHL::Exception - exception classes for DHL

=head1 DESCRIPTION

These classes are based on L<Throwable> and L<StackTrace::Auto>. The
L</as_string> method should return something readable, with a full
stack trace.  Their base class is
L<Net::Async::Webservice::Common::Exception>.

=head1 Classes

=cut

{package Net::Async::Webservice::DHL::Exception::ConfigError;
 use Moo;
 extends 'Net::Async::Webservice::Common::Exception';

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

{package Net::Async::Webservice::DHL::Exception::DHLError;
 use Moo;
 extends 'Net::Async::Webservice::Common::Exception';

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
