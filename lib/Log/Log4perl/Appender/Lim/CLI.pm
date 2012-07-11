package Log::Log4perl::Appender::Lim::CLI;

use common::sense;

use base qw(Log::Log4perl::Appender);

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        name => 'unknown name',
        %args
    };
    
    bless $self, $class;
}

sub log {
    my($self, %params) = @_;

    if (exists $self->{cli}) {
        $params{message} =~ s/[\r\n]+$//o;
        $self->{cli}->println($params{message});
    }
}

1;
