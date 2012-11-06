#!perl -T

use Test::More tests => 1;

my $pid = $$;
my $child = fork();

unless ($child) {
    use Log::Log4perl ();

    use AnyEvent ();

    use Lim::RPC::Server ();
    use Lim::Agent ();

    Log::Log4perl->init( \q(
    log4perl.logger                   = DEBUG, Screen
    log4perl.appender.Screen          = Log::Log4perl::Appender::Screen
    log4perl.appender.Screen.stderr   = 0
    log4perl.appender.Screen.layout   = Log::Log4perl::Layout::PatternLayout
    log4perl.appender.Screen.layout.ConversionPattern = %d %F [%L] %p: %m%n
    ) );

    my $cv = AnyEvent->condvar;
    my @watchers;

    push(@watchers,
        AnyEvent->signal(signal => "INT", cb => sub {
            $cv->send;
        }),
        AnyEvent->signal(signal => "QUIT", cb => sub {
            $cv->send;
        }),
        AnyEvent->signal(signal => "TERM", cb => sub {
            $cv->send;
        }),
    );
    
    my $server = Lim::RPC::Server->new(
        uri => 'http+soap://127.0.0.1:5353'
    );
    $server->serve(qw(Lim::Agent));
    push(@watchers, $server, AnyEvent->timer(after => 0, cb => sub {
        kill 14, $pid;
    }));
    $cv->recv;
    @watchers = ();
    exit;
}

use SOAP::Lite;

$SIG{ALRM} = sub { return; };
sleep(10);

my $res =
    SOAP::Lite
    -> proxy('http://127.0.0.1:5353/agent')
    -> default_ns('urn:Lim::Agent::Server')
    -> call('ReadVersion')
    -> result;

ok($res eq '0.12');

kill 15, $child;
