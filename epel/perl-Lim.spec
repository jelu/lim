Name:           perl-Lim
Version:        0.12
Release:        1%{?dist}
Summary:        Lim - Framework for RESTful JSON/XML, JSON-RPC, XML-RPC and SOAP

Group:          Development/Libraries
License:        GPL+ or Artistic
URL:            https://github.com/jelu/lim/
Source0:        lim-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
# Needed for test
BuildRequires:  perl(Test::Simple)
BuildRequires:  perl(AnyEvent) >= 5
BuildRequires:  perl(common::sense) >= 3
BuildRequires:  perl(JSON::XS) >= 2
BuildRequires:  perl(Log::Log4perl) >= 1
BuildRequires:  perl(Module::Find)
BuildRequires:  perl(SOAP::Lite) >= 0.71
BuildRequires:  perl(URI) >= 1
BuildRequires:  perl(LWP::UserAgent) >= 5
BuildRequires:  perl(YAML) >= 0.70
BuildRequires:  perl(Net::SSLeay) >= 1.35
BuildRequires:  perl(XMLRPC::Transport::HTTP::Server) >= 0.12
BuildRequires:  perl(Log::Log4perl::Appender::Lim::CLI) >= 0.12

Requires:  perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:  perl(AnyEvent) >= 5
Requires:  perl(common::sense) >= 3
Requires:  perl(JSON::XS) >= 2
Requires:  perl(Log::Log4perl) >= 1
Requires:  perl(Module::Find)
Requires:  perl(SOAP::Lite) >= 0.71
Requires:  perl(URI) >= 1
Requires:  perl(LWP::UserAgent) >= 5
Requires:  perl(YAML) >= 0.70
Requires:  perl(Net::SSLeay) >= 1.35
Requires:  perl(XMLRPC::Transport::HTTP::Server) >= 0.12
Requires:  perl(Log::Log4perl::Appender::Lim::CLI) >= 0.12

%description
Lim provides a framework for calling plugins over multiple protocols.
It uses AnyEvent for async operations and SOAP::Lite, XMLRPC::Lite and JSON::XS
for processing protocol messages.

%package -n perl-Lim-Common
Summary: Common perl libraries for Lim
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Common
Common Lim perl libraries depended by all Lim packages.

%package -n perl-Lim-Server
Summary: Lim server perl libraries
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Server
Lim server perl libraries for communicating with Lim via many different
protocols.

%package -n perl-Lim-CLI
Summary: Lim CLI perl libraries
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-CLI
Lim CLI perl libraries for controlling a local or remote Lim server.

%package -n perl-Lim-Agent-Common
Summary: Common perl libraries for lim-agentd
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Agent-Common
Common lim-agentd perl libraries.

%package -n perl-Lim-Agent-Server
Summary: Server perl libraries for lim-agentd
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Agent-Server
Server perl libraries for lim-agentd.

%package -n perl-Lim-Agent-Client
Summary: Client perl libraries for lim-agentd
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Agent-Client
Client perl libraries for communicating with lim-agentd.

%package -n perl-Lim-Agent-CLI
Summary: CLI perl libraries for lim-agentd
Group: Development/Libraries
Version: 0.12
%description -n perl-Lim-Agent-CLI
CLI perl libraries for controlling lim-agentd via lim-cli.

%package -n lim-agentd
Summary: Lim agent daemon
Group: Development/Libraries
Version: 0.12
%description -n lim-agentd
The Lim agent daemon that serves all plugins.

%package -n lim-cli
Summary: Lim command line interface
Group: Development/Libraries
Version: 0.12
%description -n lim-cli
The Lim CLI used to control a local or remote Lim agent.


%prep
%setup -q -n lim


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
mkdir -p ${RPM_BUILD_ROOT}%{_datadir}/lim/html
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'


%check
make test


%clean
rm -rf $RPM_BUILD_ROOT


%files -n perl-Lim-Common
%defattr(-,root,root,-)
%doc Changes README
%{_mandir}/man3/Lim::Component.3*
%{_mandir}/man3/Lim::RPC::Value::Collection.3*
%{_mandir}/man3/Lim::RPC::Client::TLS.3*
%{_mandir}/man3/Lim::RPC::Call.3*
%{_mandir}/man3/Lim::RPC::Value.3*
%{_mandir}/man3/Lim::Plugins.3*
%{_mandir}/man3/Lim::Component::Client.3*
%{_mandir}/man3/Lim::RPC::Client.3*
%{_mandir}/man3/Lim::Util.3*
%{_mandir}/man3/Lim.3*
%{_mandir}/man3/Lim::Error.3*
%{_mandir}/man3/Lim::RPC.3*
%{perl_vendorlib}/Lim.pm
%{perl_vendorlib}/Lim/Plugins.pm
%{perl_vendorlib}/Lim/Error.pm
%{perl_vendorlib}/Lim/Component/Client.pm
%{perl_vendorlib}/Lim/Util.pm
%{perl_vendorlib}/Lim/RPC/Client.pm
%{perl_vendorlib}/Lim/RPC/Client/TLS.pm
%{perl_vendorlib}/Lim/RPC/Value/Collection.pm
%{perl_vendorlib}/Lim/RPC/Call.pm
%{perl_vendorlib}/Lim/RPC/Value.pm
%{perl_vendorlib}/Lim/Component.pm
%{perl_vendorlib}/Lim/RPC.pm

%files -n perl-Lim-Server
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Component::Server.3*
%{_mandir}/man3/Lim::RPC::Callback.3*
%{_mandir}/man3/Lim::RPC::Callback::XMLRPC.3*
%{_mandir}/man3/Lim::RPC::Callback::SOAP.3*
%{_mandir}/man3/Lim::RPC::Callback::JSON.3*
%{_mandir}/man3/Lim::RPC::Server::Client.3*
%{_mandir}/man3/Lim::RPC::Callback::JSONRPC.3*
%{_mandir}/man3/Lim::RPC::Server.3*
%{perl_vendorlib}/Lim/Component/Server.pm
%{perl_vendorlib}/Lim/RPC/Server/Client.pm
%{perl_vendorlib}/Lim/RPC/Callback.pm
%{perl_vendorlib}/Lim/RPC/Callback/XMLRPC.pm
%{perl_vendorlib}/Lim/RPC/Callback/SOAP.pm
%{perl_vendorlib}/Lim/RPC/Callback/JSONRPC.pm
%{perl_vendorlib}/Lim/RPC/Callback/JSON.pm
%{perl_vendorlib}/Lim/RPC/Server.pm
%{_datadir}/lim/html

%files -n perl-Lim-CLI
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Component::CLI.3*
%{_mandir}/man3/Lim::CLI.3*
%{perl_vendorlib}/Lim/Component/CLI.pm
%{perl_vendorlib}/Lim/CLI.pm

%files -n perl-Lim-Agent-Common
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Agent.3*
%{perl_vendorlib}/Lim/Agent.pm

%files -n perl-Lim-Agent-Server
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Agent::Server.3*
%{perl_vendorlib}/Lim/Agent/Server.pm

%files -n perl-Lim-Agent-Client
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Agent::Client.3*
%{perl_vendorlib}/Lim/Agent/Client.pm

%files -n perl-Lim-Agent-CLI
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Agent::CLI.3*
%{perl_vendorlib}/Lim/Agent/CLI.pm

%files -n lim-agentd
%defattr(-,root,root,-)
%{_mandir}/man1/lim-agentd.1*
%{_bindir}/lim-agentd

%files -n lim-cli
%defattr(-,root,root,-)
%{_mandir}/man1/lim-cli.1*
%{_bindir}/lim-cli


%changelog
* Tue Aug 07 2012 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.12-1
- Initial package for Fedora

