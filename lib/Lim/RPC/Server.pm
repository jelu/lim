package Lim::RPC::Server;

use common::sense;
use Carp;

use Log::Log4perl ();
use Scalar::Util qw(blessed weaken);

use AnyEvent ();
use AnyEvent::Socket ();
use AnyEvent::TLS ();

use Lim ();
use Lim::RPC ();
use Lim::RPC::Value ();
use Lim::RPC::Value::Collection ();
use Lim::RPC::Server::Client ();

=head1 NAME

...

=head1 VERSION

See L<Lim> for version.

=cut

our $VERSION = $Lim::VERSION;

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
        client => {},
        module => {}
    };
    bless $self, $class;
    my $real_self = $self;
    weaken($self);
    
    unless (defined $args{key} and -f $args{key}) {
        confess __PACKAGE__, ': No key file specified or not found';
    }
    unless (defined $args{host}) {
        confess __PACKAGE__, ': No host specified';
    }
    unless (defined $args{port}) {
        confess __PACKAGE__, ': No port specified';
    }
    
    $self->{tls_ctx} = AnyEvent::TLS->new(
        method => 'any',
        ca_file => $args{key},
        cert_file => $args{key},
        key_file => $args{key},
        verify => 1,
        verify_require_client_cert => 1
        );

    $self->{host} = $args{host};
    $self->{port} = $args{port};
    if (defined $args{html}) {
        $self->{html} = $args{html};
        
        unless (-d $self->{html} and -r $self->{html} and -x $self->{html}) {
            confess __PACKAGE__, ': Path to html "', $self->{html}, '" is invalid';
        }
    }

    $self->{socket} = AnyEvent::Socket::tcp_server $self->{host}, $self->{port}, sub {
        my ($fh, $host, $port) = @_;
        
        my $handle;
        $handle = Lim::RPC::Server::Client->new(
            server => $self,
            fh => $fh,
            tls_ctx => $self->{tls_ctx},
            on_error => sub {
                my ($handle, $fatal, $message) = @_;
                
                $self->{logger}->warn($handle, ' Error: ', $message);
                
                delete $self->{client}->{$handle};
            },
            on_eof => sub {
                my ($handle) = @_;
                
                $self->{logger}->debug($handle, ' EOF');
                
                delete $self->{client}->{$handle};
            });
        
        if (exists $self->{html}) {
            $handle->set_html($self->{html});
        }
        
        $self->{client}->{$handle} = $handle;
    }, sub {
        my (undef, $host, $port) = @_;
        
        Lim::DEBUG and $self->{logger}->debug(__PACKAGE__, ' ', $self, ' ready at ', $host, ':', $port);
        
        Lim::SRV_LISTEN;
    };

    Lim::OBJ_DEBUG and $self->{logger}->debug('new ', __PACKAGE__, ' ', $self);
    $real_self;
}

sub DESTROY {
    my ($self) = @_;
    Lim::OBJ_DEBUG and $self->{logger}->debug('destroy ', __PACKAGE__, ' ', $self);
    
    delete $self->{client};
    delete $self->{socket};
    delete $self->{module};
}

=head2 function2

=cut

sub serve {
    my ($self) = shift;
    
    foreach my $module (@_) {
        my $obj;

        eval {
            $obj = $module->Server;
        };
        if (!defined $obj or $@) {
            $self->{logger}->warn('Can not serve ', $module, (defined $@ ? ': '.$@ : ''));
            next;
        }

        if ($obj->isa('Lim::Component::Server')) {
            my $name = lc($module->Module);
            
            if (exists $self->{module}->{$name}) {
                $self->{logger}->warn('Can not serve ', $name, ': module already served');
                next;
            }
            
            unless ($module->VERSION) {
                $self->{logger}->warn('Can not serve ', $name, ': no VERSION specified in module');
                next;
            }
            
            my $calls = $module->Calls;
            unless ($calls) {
                $self->{logger}->info('Not serving ', $name, ', nothing to serve');
                next;
            }
            unless (ref($calls) eq 'HASH') {
                $self->{logger}->warn('Can not serve ', $name, ': Calls() return was invalid');
                next;
            }
            unless (%$calls) {
                $self->{logger}->info('Not serving ', $name, ', nothing to serve');
                next;
            }
            foreach my $call (keys %$calls) {
                unless ($obj->can($call)) {
                    $self->{logger}->warn('Can not serve ', $name, ': Missing specified call ', $call, ' function');
                    undef($calls);
                    last;
                }
                unless ($obj->can('__lim_rpc_'.$call)) {
                    my ($orig_call, $rpc_call, $valueof);
                    my $call_def = $calls->{$call};
                    
                    unless (ref($call_def) eq 'HASH') {
                        $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid definition');
                        undef($calls);
                        last;
                    }
                    
                    if (exists $call_def->{in}) {
                        unless (ref($call_def->{in}) eq 'HASH') {
                            $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid in parameter definition');
                            undef($calls);
                            last;
                        }
                        
                        my @keys = keys %{$call_def->{in}};
                        unless (scalar @keys) {
                            $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid in parameter definition');
                            undef($calls);
                            last;
                        }
                        
                        $valueof = '//'.$call.'/';
                        
                        my @values = ($call_def->{in});
                        while (defined $calls and (my $value = shift(@values))) {
                            foreach my $key (keys %$value) {
                                if (ref($value->{$key}) eq 'HASH') {
                                    if (exists $value->{$key}->{''}) {
                                        eval {
                                            my $collection = Lim::RPC::Value::Collection->new($value->{$key}->{''});
                                            delete $value->{$key}->{''};
                                            $value->{$key} = $collection->set_children($value->{$key});
                                        };
                                        unless ($@) {
                                            push(@values, $value->{$key}->children);
                                            next;
                                        }
                                        $self->{logger}->warn('Unable to create Lim::RPC::Value::Collection: ', $@);
                                    }
                                    else {
                                        push(@values, $value->{$key});
                                        next;
                                    }
                                }
                                elsif (blessed $value->{$key}) {
                                    if ($value->{$key}->isa('Lim::RPC::Value')) {
                                        next;
                                    }
                                    if ($value->{$key}->isa('Lim::RPC::Value::Collection')) {
                                        push(@values, $value->{$key}->children);
                                        next;
                                    }
                                }
                                else {
                                    eval {
                                        $value->{$key} = Lim::RPC::Value->new($value->{$key});
                                    };
                                    unless ($@) {
                                        next;
                                    }
                                    $self->{logger}->warn('Unable to create Lim::RPC::Value: ', $@);
                                }

                                $self->{logger}->warn('Can not server ', $name, ': call ', $call, ' has invalid in parameter definition');
                                undef($calls);
                            }
                        }
                        
                        unless (defined $calls) {
                            last;
                        }
                    }
                    
                    if (exists $call_def->{out}) {
                        unless (ref($call_def->{out}) eq 'HASH') {
                            $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid out parameter definition');
                            undef($calls);
                            last;
                        }
                        
                        my @keys = keys %{$call_def->{out}};
                        unless (scalar @keys) {
                            $self->{logger}->warn('Can not serve ', $name, ': call ', $call, ' has invalid out parameter definition');
                            undef($calls);
                            last;
                        }

                        my @values = ($call_def->{out});
                        while (defined $calls and (my $value = shift(@values))) {
                            foreach my $key (keys %$value) {
                                if (ref($value->{$key}) eq 'HASH') {
                                    if (exists $value->{$key}->{''}) {
                                        eval {
                                            my $collection = Lim::RPC::Value::Collection->new($value->{$key}->{''});
                                            delete $value->{$key}->{''};
                                            $value->{$key} = $collection->set_children($value->{$key});
                                        };
                                        unless ($@) {
                                            push(@values, $value->{$key}->children);
                                            next;
                                        }
                                        $self->{logger}->warn('Unable to create Lim::RPC::Value::Collection: ', $@);
                                    }
                                    else {
                                        push(@values, $value->{$key});
                                        next;
                                    }
                                }
                                elsif (blessed $value->{$key}) {
                                    if ($value->{$key}->isa('Lim::RPC::Value')) {
                                        next;
                                    }
                                    if ($value->{$key}->isa('Lim::RPC::Value::Collection')) {
                                        push(@values, $value->{$key}->children);
                                        next;
                                    }
                                }
                                else {
                                    eval {
                                        $value->{$key} = Lim::RPC::Value->new($value->{$key});
                                    };
                                    unless ($@) {
                                        next;
                                    }
                                    $self->{logger}->warn('Unable to create Lim::RPC::Value: ', $@);
                                }

                                $self->{logger}->warn('Can not server ', $name, ': call ', $call, ' has invalid out parameter definition');
                                undef($calls);
                            }
                        }
                        
                        unless (defined $calls) {
                            last;
                        }
                    }
                    
                    $orig_call = ref($obj).'::'.$call;
                    $call = '__lim_rpc_'.$call;;
                    $rpc_call = ref($obj).'::'.$call;
                    
                    my $self2 = $self;
                    weaken($self2);
                    
                    no strict 'refs';
                    *$rpc_call = \&$orig_call;
                    *$orig_call = sub {
                        my ($self, $cb, $q, @args) = Lim::RPC::C(@_, $valueof);
                        
                        Lim::RPC_DEBUG and defined $self2 and $self2->{logger}->debug('Call to ', $self, ' ', $orig_call);
                        
                        if (!defined $q) {
                            $q = {};
                        }
                        if (ref($q) ne 'HASH') {
                            defined $self2 and $self2->{logger}->warn($self, '->', $orig_call, '() called without data as hash');
                            $self->Error($cb);
                            return;
                        }
                        
                        if (exists $call_def->{in}) {
                            eval {
                                Lim::RPC::V($q, $call_def->{in});
                            };
                            if ($@) {
                                defined $self2 and $self2->{logger}->warn($self, '->', $orig_call, '() data validation failed: ', $@);
                                $self->Error($cb);
                                return;
                            }
                        }
                        elsif (%$q) {
                            $self->Error($cb);
                            return;
                        }
                        $cb->set_call_def($call_def);
                        
                        $self->$call($cb, $q, @args);
                        return;
                    };
                }
            }
            unless ($calls) {
                next;
            }
            
            my $wsdl;
            {
                my ($tns, $soap_name);
                
                $tns = $module.'::Server';
                ($soap_name = $module) =~ s/:://go;
                
                $wsdl =
'<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<wsdl:definitions
 xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/"
 xmlns:tns="urn:'.$tns.'"
 xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/"
 xmlns:xsd="http://www.w3.org/2001/XMLSchema"
 name="'.$soap_name.'"
 targetNamespace="urn:'.$tns.'">

';

                # Generate types
                $wsdl .= ' <wsdl:types>
  <xsd:schema targetNamespace="urn:'.$tns.'">
';
                foreach my $call (keys %$calls) {
                    my $h = $calls->{$call};
                    
                    if (exists $h->{in}) {
                        $wsdl .= '   <xsd:element name="'.$call.'">
<xsd:complexType>
<xsd:choice minOccurs="0" maxOccurs="unbounded">
';
                        $wsdl .= Lim::RPC::Server::__wsdl_gen_complex_types($h->{in});
                        $wsdl .= '</xsd:choice>
</xsd:complexType>
   </xsd:element>
';
                    }
                    else {
                        $wsdl .= '   <xsd:element name="'.$call.'" />
';
                    }
                    
                    if (exists $h->{out}) {
                        $wsdl .= '   <xsd:element name="'.$call.'Response">
<xsd:complexType>
<xsd:choice minOccurs="0" maxOccurs="unbounded">
';
                        $wsdl .= Lim::RPC::Server::__wsdl_gen_complex_types($h->{out});
                        $wsdl .= '</xsd:choice>
</xsd:complexType>
   </xsd:element>
';
                    }
                    else {
                        $wsdl .= '   <xsd:element name="'.$call.'Response" />
';
                    }
                }
                $wsdl .= '  </xsd:schema>
 </wsdl:types>

';
                
                # Generate message
                foreach my $call (keys %$calls) {
                    $wsdl .= ' <wsdl:message name="'.$call.'">
  <wsdl:part element="tns:'.$call.'" name="parameters" />
 </wsdl:message>
';
                    $wsdl .= ' <wsdl:message name="'.$call.'Response">
  <wsdl:part element="tns:'.$call.'Response" name="parameters" />
 </wsdl:message>
';
                }
                $wsdl .= '
';
                
                # Generate portType
                $wsdl .= ' <wsdl:portType name="'.$soap_name.'">
';
                foreach my $call (keys %$calls) {
                    $wsdl .= '  <wsdl:operation name="'.$call.'">
   <wsdl:input message="tns:'.$call.'" />
   <wsdl:output message="tns:'.$call.'Response" />
  </wsdl:operation>
';
                }
                $wsdl .= ' </wsdl:portType>

';
                
                # Generate binding
                $wsdl .= ' <wsdl:binding name="'.$soap_name.'SOAP" type="tns:'.$soap_name.'">
  <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http" />
';
                foreach my $call (keys %$calls) {
                    $wsdl .= '  <wsdl:operation name="'.$call.'">
   <soap:operation soapAction="urn:'.$tns.'#'.$call.'" />
   <wsdl:input>
    <soap:body use="literal" />
   </wsdl:input>
   <wsdl:output>
    <soap:body use="literal" />
   </wsdl:output>
  </wsdl:operation>
';
                }
                $wsdl .= ' </wsdl:binding>

';

                # Generate service
                $wsdl .= ' <wsdl:service name="'.$soap_name.'">
  <wsdl:port binding="tns:'.$soap_name.'SOAP" name="'.$soap_name.'SOAP">
   <soap:address location="';

                $wsdl = [ $wsdl, '" />
  </wsdl:port>
 </wsdl:service>

</wsdl:definitions>
' ];
            }
            
            Lim::DEBUG and $self->{logger}->debug('serving ', $name);
            
            $self->{module}->{$name} = {
                name => $name,
                module => $module,
                obj => $obj,
                wsdl => $wsdl,
                calls => $calls
            };
        }
    }
    
    $self;
}

=head2 function2

=cut

sub __wsdl_gen_complex_types {
    my @values = @_;
    my $wsdl = '';

    while (scalar @values) {
        my $values = pop(@values);
        
        if (ref($values) eq 'ARRAY' and scalar @$values == 2) {
            my $key = $values->[0];
            $values = $values->[1];
            
            if (blessed $values) {
                $wsdl .= '<xsd:element minOccurs="'.($values->required ? '1' : '0').'" maxOccurs="unbounded" name="'.$key.'"><xsd:complexType><xsd:choice minOccurs="0" maxOccurs="unbounded">
';
                if ($values->isa('Lim::RPC::Value::Collection')) {
                    $values = $values->children;
                }
            }
            else {
                $wsdl .= '<xsd:element minOccurs="0" maxOccurs="unbounded" name="'.$key.'"><xsd:complexType><xsd:choice minOccurs="0" maxOccurs="unbounded">
';
            }
        }
        
        if (ref($values) eq 'HASH') {
            my $nested = 0;
            
            foreach my $key (keys %$values) {
                if (blessed $values->{$key}) {
                    if ($values->{$key}->isa('Lim::RPC::Value::Collection')) {
                        unless ($nested) {
                            $nested = 1;
                            push(@values, 1);
                        }
                        push(@values, [$key, $values->{$key}->children]);
                    }
                    else {
                        $wsdl .= '<xsd:element minOccurs="'.($values->{$key}->required ? '1' : '0').'" maxOccurs="1" name="'.$key.'" type="'.$values->{$key}->xsd_type.'" />
    ';
                    }
                }
                elsif (ref($values->{$key}) eq 'HASH') {
                    unless ($nested) {
                        $nested = 1;
                        push(@values, 1);
                    }
                    push(@values, [$key, $values->{$key}]);
                }
            }
            
            if ($nested) {
                next;
            }
        }
        
        unless (scalar @values) {
            last;
        }
        
        $wsdl .= '</xsd:choice></xsd:complexType></xsd:element>
';
    }
    
    $wsdl;
}

=head2 function2

=cut

sub key {
    $_[0]->{key};
}

=head2 function2

=cut

sub port {
    $_[0]->{port};
}

=head2 function2

=cut

sub host {
    $_[0]->{host};
}

=head2 function2

=cut

sub html {
    $_[0]->{html};
}

=head1 AUTHOR

Jerry Lundström, C<< <lundstrom.jerry at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to L<https://github.com/jelu/lim/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

perldoc Lim

You can also look for information at:

=over 4

=item * Lim issue tracker (report bugs here)

L<https://github.com/jelu/lim/issues>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Jerry Lundström.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Lim::RPC::Server
