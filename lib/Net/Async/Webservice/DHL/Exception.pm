package Net::Async::Webservice::DHL::Exception;
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
