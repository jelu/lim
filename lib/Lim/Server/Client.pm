package Lim::Server::Client;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(weaken);

use AnyEvent ();
use AnyEvent::Handle ();

use HTTP::Status qw(:constants);
use HTTP::Request ();
use HTTP::Response ();
use URI ();
use URI::QueryParam ();

use Lim ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

sub MAX_REQUEST_LEN     (){ 64 * 1024 }

=head1 SYNOPSIS

...

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub new {
    my $this = shift;
    my $class = ref($this) || $this;
    my %args = ( @_ );
    my $self = {
        logger => Log::Log4perl->get_logger,
        rbuf => ''
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);

    unless (defined $args{fh}) {
        croak __PACKAGE__, ': Missing fh (file handle)';
    }
    unless (defined $args{tls_ctx}) {
        croak __PACKAGE__, ': Missing tls_ctx (TLS context)';
    }
    unless (defined $args{html}) {
        croak __PACKAGE__, ': Missing hmtl (Path to HTML files)';
    }
    unless (defined $args{server}) {
        croak __PACKAGE__, ': Missing server object';
    }

    if (exists $args{on_error} and ref($args{on_error}) eq 'CODE') {
        $self->{on_error} = $args{on_error};
    }
    if (exists $args{on_eof} and ref($args{on_eof}) eq 'CODE') {
        $self->{on_eof} = $args{on_eof};
        $args{on_eof} = sub {
            $self->close;
            $self->{on_eof}->($self);
        };
    }

    $self->{html} = $args{html};
    $self->{server} = $args{server};
    $self->{handle} = AnyEvent::Handle->new(
        fh => $args{fh},
        tls => 'accept',
        tls_ctx => $args{tls_ctx},
        on_error => sub {
            my ($handle, $fatal, $message) = @_;
            
            $self->{logger}->warn($handle, ' Error: ', $message);

            if (exists $self->{on_error}) {
                $self->{on_error}->($self, $fatal, $message);
            }
            $handle->destroy;
        },
        on_eof => sub {
            my ($handle) = @_;
            
            $self->{logger}->warn($handle, ' EOF');
            
            if (exists $self->{on_eof}) {
                $self->{on_eof}->($self);
            }
            $handle->destroy;
        },
        on_read => sub {
            my ($handle) = @_;
            
            if ((length($self->{rbuf}) + length($handle->{rbuf})) > MAX_REQUEST_LEN) {
                if (exists $self->{on_error}) {
                    $self->{on_error}->($self, 1, 'Request too long');
                }
                $handle->push_shutdown;
                $handle->destroy;
                return;
            }
            
            $self->{rbuf} .= $handle->{rbuf};
            $handle->{rbuf} = '';
            
            if ($self->{rbuf} =~ /\r\n\r\n$/o) {
                my $request = HTTP::Request->parse($self->{rbuf});
                my $response = HTTP::Response->new;
                $response->request($request);
                $response->protocol($request->protocol);
                my $uri = $request->uri;

use Data::Dumper;
print Dumper($request),"\n";
                
                Lim::DEBUG and $self->{logger}->debug('Request recieved for ', $uri);
                
                if ($uri =~ /^\/([a-zA-Z]+)\/([a-zA-Z]+)\/{0,1}(.*)/o) {
                    my ($module, $function, $parameters) = ($1, $2, $3);
                    my ($method, $call, @parameters);
                    
                    $method = lc($request->method);
                    $module = lc($module);
                    $function = lc($function);
                    $call = ucfirst($method).ucfirst($function);
                    
                    if (defined $parameters) {
                        foreach my $parameter (split(/\//o, $parameters)) {
                            # TODO urldecode $parameter
                            push(@parameters, $parameter);
                        }
                    }
                    
                    if (exists $self->{server}->{module}->{$module}) {
                        my $moduleObj = $self->{server}->{module}->{$module};
                        
                        if ($moduleObj->can($call)) {
                            #$moduleObj->$call($request, $response, @parameters);
                        }
                    }
                }
                elsif ($uri =~ /^\//o) {
                    my $file = $self->{html};
                    
                    if ($uri eq '/') {
                        $uri = '/index.html';
                    }

                    $uri =~ s/\///o;
                    foreach my $path (split(/\//o, $uri)) {
                        if ($path eq '.' or $path eq '..') {
                            undef($file);
                            last;
                        }
                        if (-d $file.'/'.$path) {
                            $file .= '/'.$path;
                        }
                        elsif (-f $file.'/'.$path) {
                            $file .= '/'.$path;
                            last;
                        }
                        else {
                            undef($file);
                            last;
                        }
                    }
                    
                    if (defined $file and open(FILE, $file)) {
                        my ($read, $buffer, $content) = (0, '', '');

                        Lim::DEBUG and $self->{logger}->debug('Sending file ', $file);
                        
                        while (($read = read(FILE, $buffer, 64*1024))) {
                            $content .= $buffer;
                        }
                        unless (defined $read) {
                            $response->code(HTTP_INTERNAL_SERVER_ERROR);
                        }
                        else {
                            $response->content($content);
                            
                            if ($file =~ /\.js$/o) {
                                $response->header('Content-Type' => 'text/javascript');
                            }
                            elsif ($file =~ /\.css$/o) {
                                $response->header('Content-Type' => 'text/css');
                            }
                        }
                        close(FILE);
                    }
                    else {
                        $response->code(HTTP_NOT_FOUND);
                    }
                }
                else {
                    $response->code(HTTP_NOT_FOUND);
                }
                
                unless ($response->code) {
                    $response->code(HTTP_OK);
                }
                
                if ($response->code != HTTP_OK and !length($response->content)) {
                    $response->content($response->code.' '.HTTP::Status::status_message($response->code)."\r\n");
                }
                
                $response->header('Connection' => 'close');
                $response->header('Content-Length' => length($response->content));
                unless (defined $response->header('Content-Type')) {
                    $response->header('Content-Type' => 'text/html');
                }
                
                unless ($response->protocol) {
                    $response->protocol('HTTP/1.1');
                }
                
                $handle->push_write($response->protocol.' '.$response->code.' '.HTTP::Status::status_message($response->code)."\r\n");
                $handle->push_write($response->headers_as_string("\r\n"));
                $handle->push_write("\r\n");
                $handle->push_write($response->content);
                $handle->push_shutdown;
            }
        });
    
    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);

    $self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    if (defined $self->{handle}) {
        $self->{handle}->push_shutdown;
    }
    delete $self->{handle};
}

sub handle {
    $_[0]->{handle};
}

sub set_handle {
    $_[0]->{handle} = $_[1] if (defined $_[1]);
    
    $_[0];
}

=head2 function2

=cut

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-lim at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Lim>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lim>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lim>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lim>

=item * Search CPAN

L<http://search.cpan.org/dist/Lim/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::Server
