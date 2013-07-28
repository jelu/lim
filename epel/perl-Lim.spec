Name:           perl-Lim
Version:        0.13
Release:        1%{?dist}
Summary:        Lim - Framework for RESTful JSON/XML, JSON-RPC, XML-RPC and SOAP

Group:          Development/Libraries
License:        GPL+ or Artistic
URL:            https://github.com/jelu/lim/
Source0:        lim-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root-%(%{__id_u} -n)

BuildArch:      noarch
BuildRequires:  perl(ExtUtils::MakeMaker)
BuildRequires:  perl(Test::Simple)
BuildRequires:  perl(Net::SSLeay) >= 1.35
BuildRequires:  perl(common::sense)
BuildRequires:  perl(YAML)
BuildRequires:  perl(AnyEvent)
BuildRequires:  perl(EV)
BuildRequires:  perl(Module::Find)
BuildRequires:  perl(Digest::SHA)
BuildRequires:  perl(JSON::XS)
BuildRequires:  perl(LWP::MediaTypes)

Requires:  perl(:MODULE_COMPAT_%(eval "`%{__perl} -V:version`"; echo $version))
Requires:  perl(Net::SSLeay) >= 1.35

%description
Lim provides a framework for calling plugins over multiple protocols.
It uses AnyEvent for async operations and SOAP::Lite, XMLRPC::Lite and JSON::XS
for processing protocol messages.

%package -n perl-Lim-Common
Summary: Common perl libraries for Lim
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Common
Common Lim perl libraries depended by all Lim packages.

%package -n perl-Lim-Server
Summary: Lim server perl libraries
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Server
Lim server perl libraries for communicating with Lim via many different
protocols.

%package -n perl-Lim-CLI
Summary: Lim CLI perl libraries
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-CLI
Lim CLI perl libraries for controlling a local or remote Lim server.

%package -n perl-Lim-Agent-Common
Summary: Common perl libraries for lim-agentd
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Agent-Common
Common lim-agentd perl libraries.

%package -n perl-Lim-Agent-Server
Summary: Server perl libraries for lim-agentd
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Agent-Server
Server perl libraries for lim-agentd.

%package -n perl-Lim-Agent-Client
Summary: Client perl libraries for lim-agentd
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Agent-Client
Client perl libraries for communicating with lim-agentd.

%package -n perl-Lim-Agent-CLI
Summary: CLI perl libraries for lim-agentd
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Agent-CLI
CLI perl libraries for controlling lim-agentd via lim-cli.

%package -n lim-agentd
Requires(pre): shadow-utils
Requires(post): chkconfig
Requires(post): net-tools
Requires(post): openssl
Requires(post): openssl-perl
Requires(preun): chkconfig
Requires(preun): initscripts
Requires(postun): initscripts
Requires: lim-common
Summary: Lim agent daemon
Group: Development/Libraries
Version: 0.13
%description -n lim-agentd
The Lim agent daemon that serves all plugins.

%package -n lim-cli
Requires(post): net-tools
Requires(post): openssl
Requires(post): openssl-perl
Requires: lim-common
Summary: Lim command line interface
Group: Development/Libraries
Version: 0.13
%description -n lim-cli
The Lim CLI used to control a local or remote Lim agent.

%package -n lim-common
Summary: Lim common files
Group: Development/Libraries
Version: 0.13
%description -n lim-common
Common Lim files and directories.

%package -n perl-Lim-Transport-HTTP
Summary: Lim HTTP/HTTPS transport perl libraries
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Transport-HTTP
Lim perl libraries for HTTP/HTTPS transport.

%package -n perl-Lim-Protocol-REST
Summary: Lim REST protocol perl libraries
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Protocol-REST
Lim perl libraries for REST protocol.

%package -n perl-Lim-Protocol-SOAP
Summary: Lim SOAP protocol perl libraries
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Protocol-SOAP
Lim perl libraries for SOAP protocol.

%package -n perl-Lim-Protocol-XMLRPC
Summary: Lim XMLRPC protocol perl libraries
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Protocol-XMLRPC
Lim perl libraries for XMLRPC protocol.

%package -n perl-Lim-Protocol-JSONRPC
Summary: Lim JSONRPC protocol perl libraries
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Protocol-JSONRPC
Lim perl libraries for JSONRPC protocol.

%package -n perl-Lim-Protocol-HTTP
Summary: Lim HTTP protocol perl libraries
Group: Development/Libraries
Version: 0.13
%description -n perl-Lim-Protocol-HTTP
Lim perl libraries for HTTP protocol.

%package -n lim-management-console-common
Requires: lim-agentd
Summary: Lim Management Console common files
Group: Development/Libraries
Version: 0.13
%description -n lim-management-console-common
Common Lim Management Console files and directories.

%package -n lim-management-console-agent
Requires: lim-management-console-common
Summary: Lim Agent Daemon's Management Console files
Group: Development/Libraries
Version: 0.13
%description -n lim-management-console-agent
Lim Agent Daemon's Management Console files.


%prep
%setup -q -n lim


%build
%{__perl} Makefile.PL INSTALLDIRS=vendor
make %{?_smp_mflags}


%install
rm -rf $RPM_BUILD_ROOT
make pure_install PERL_INSTALL_ROOT=$RPM_BUILD_ROOT
find $RPM_BUILD_ROOT -type f -name .packlist -exec rm -f {} ';'
mkdir -p %{buildroot}%{_sysconfdir}/rc.d/init.d
install -m 755 %{_builddir}/lim/epel/lim-agentd %{buildroot}%{_sysconfdir}/rc.d/init.d/lim-agentd
mkdir -p %{buildroot}%{_sysconfdir}/lim
mkdir -p %{buildroot}%{_sysconfdir}/lim/agent.d
mkdir -p %{buildroot}%{_sysconfdir}/lim/cli.d
install -m 644 %{_builddir}/lim/etc/lim/agent.yaml %{buildroot}%{_sysconfdir}/lim/
install -m 644 %{_builddir}/lim/etc/lim/agent.d/README %{buildroot}%{_sysconfdir}/lim/agent.d/
install -m 644 %{_builddir}/lim/etc/lim/agent.d/lim-rpc-transport-http.yaml %{buildroot}%{_sysconfdir}/lim/agent.d/
install -m 644 %{_builddir}/lim/etc/lim/agent.d/lim-rpc-tls.yaml %{buildroot}%{_sysconfdir}/lim/agent.d/
install -m 644 %{_builddir}/lim/etc/lim/cli.yaml %{buildroot}%{_sysconfdir}/lim/
install -m 644 %{_builddir}/lim/etc/lim/cli.d/README %{buildroot}%{_sysconfdir}/lim/cli.d/
mkdir -p %{buildroot}%{_sysconfdir}/lim/ssl/certs
mkdir -p %{buildroot}%{_sysconfdir}/lim/ssl/private
install -m 644 %{_builddir}/lim/etc/lim/ssl/certs/README %{buildroot}%{_sysconfdir}/lim/ssl/certs/
install -m 644 %{_builddir}/lim/etc/lim/ssl/private/README %{buildroot}%{_sysconfdir}/lim/ssl/private/
mkdir -p %{buildroot}%{_datadir}/lim/html
mkdir -p %{buildroot}%{_datadir}/lim/html/_css
mkdir -p %{buildroot}%{_datadir}/lim/html/_js
mkdir -p %{buildroot}%{_datadir}/lim/html/_agent
mkdir -p %{buildroot}%{_datadir}/lim/html/_agent/js
mkdir -p %{buildroot}%{_datadir}/lim/html/_img
install -m 644 %{_builddir}/lim/html/home.html %{buildroot}%{_datadir}/lim/html/home.html
install -m 644 %{_builddir}/lim/html/_css/bootstrap.min.css %{buildroot}%{_datadir}/lim/html/_css/bootstrap.min.css
install -m 644 %{_builddir}/lim/html/_css/application.css %{buildroot}%{_datadir}/lim/html/_css/application.css
install -m 644 %{_builddir}/lim/html/_css/prettify.css %{buildroot}%{_datadir}/lim/html/_css/prettify.css
install -m 644 %{_builddir}/lim/html/index.html %{buildroot}%{_datadir}/lim/html/index.html
install -m 644 %{_builddir}/lim/html/_js/application.js %{buildroot}%{_datadir}/lim/html/_js/application.js
install -m 644 %{_builddir}/lim/html/_js/html5shiv.js %{buildroot}%{_datadir}/lim/html/_js/html5shiv.js
install -m 644 %{_builddir}/lim/html/_js/jquery.min.js %{buildroot}%{_datadir}/lim/html/_js/jquery.min.js
install -m 644 %{_builddir}/lim/html/_js/bootstrap.min.js %{buildroot}%{_datadir}/lim/html/_js/bootstrap.min.js
install -m 644 %{_builddir}/lim/html/_js/prettify.js %{buildroot}%{_datadir}/lim/html/_js/prettify.js
install -m 644 %{_builddir}/lim/html/_agent/system_information.html %{buildroot}%{_datadir}/lim/html/_agent/system_information.html
install -m 644 %{_builddir}/lim/html/_agent/plugins.html %{buildroot}%{_datadir}/lim/html/_agent/plugins.html
install -m 644 %{_builddir}/lim/html/_agent/index.html %{buildroot}%{_datadir}/lim/html/_agent/index.html
install -m 644 %{_builddir}/lim/html/_agent/js/application.js %{buildroot}%{_datadir}/lim/html/_agent/js/application.js
install -m 644 %{_builddir}/lim/html/_img/glyphicons-halflings-white.png %{buildroot}%{_datadir}/lim/html/_img/glyphicons-halflings-white.png
install -m 644 %{_builddir}/lim/html/_img/glyphicons-halflings.png %{buildroot}%{_datadir}/lim/html/_img/glyphicons-halflings.png


%check
make test


%clean
rm -rf $RPM_BUILD_ROOT


%files -n perl-Lim-Common
%defattr(-,root,root,-)
%doc Changes README
%{_mandir}/man3/Lim::Component.3*
%{_mandir}/man3/Lim::RPC::Value::Collection.3*
%{_mandir}/man3/Lim::RPC::TLS.3*
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
%{perl_vendorlib}/Lim/RPC/TLS.pm
%{perl_vendorlib}/Lim/RPC/Value/Collection.pm
%{perl_vendorlib}/Lim/RPC/Call.pm
%{perl_vendorlib}/Lim/RPC/Value.pm
%{perl_vendorlib}/Lim/Component.pm
%{perl_vendorlib}/Lim/RPC.pm

%files -n perl-Lim-Server
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::Component::Server.3*
%{_mandir}/man3/Lim::RPC::Callback.3*
%{_mandir}/man3/Lim::RPC::Server.3*
%{_mandir}/man3/Lim::RPC::Transport.3*
%{_mandir}/man3/Lim::RPC::Transports.3*
%{_mandir}/man3/Lim::RPC::Protocol.3*
%{_mandir}/man3/Lim::RPC::Protocols.3*
%{_mandir}/man3/Lim::RPC::URIMaps.3*
%{perl_vendorlib}/Lim/Component/Server.pm
%{perl_vendorlib}/Lim/RPC/Callback.pm
%{perl_vendorlib}/Lim/RPC/Server.pm
%{perl_vendorlib}/Lim/RPC/Transport.pm
%{perl_vendorlib}/Lim/RPC/Transports.pm
%{perl_vendorlib}/Lim/RPC/Protocol.pm
%{perl_vendorlib}/Lim/RPC/Protocols.pm
%{perl_vendorlib}/Lim/RPC/URIMaps.pm
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
%attr(0755,root,root) %{_sysconfdir}/rc.d/init.d/lim-agentd
%config %{_sysconfdir}/lim/agent.yaml
%config %{_sysconfdir}/lim/agent.d/lim-rpc-transport-http.yaml
%config %{_sysconfdir}/lim/agent.d/lim-rpc-tls.yaml
%{_sysconfdir}/lim/agent.d/README

%files -n lim-cli
%defattr(-,root,root,-)
%{_mandir}/man1/lim-cli.1*
%{_bindir}/lim-cli
%config %{_sysconfdir}/lim/cli.yaml
%{_sysconfdir}/lim/cli.d/README

%files -n lim-common
%{_sysconfdir}/lim/ssl

%files -n perl-Lim-Transport-HTTP
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::RPC::Transport::HTTP.3*
%{_mandir}/man3/Lim::RPC::Transport::HTTPS.3*
%{perl_vendorlib}/Lim/RPC/Transport/HTTP.pm
%{perl_vendorlib}/Lim/RPC/Transport/HTTPS.pm
%config %{_sysconfdir}/lim/agent.d/lim-rpc-transport-http.yaml

%files -n perl-Lim-Protocol-REST
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::RPC::Protocol::REST.3*
%{perl_vendorlib}/Lim/RPC/Protocol/REST.pm

%files -n perl-Lim-Protocol-SOAP
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::RPC::Protocol::SOAP.3*
%{perl_vendorlib}/Lim/RPC/Protocol/SOAP.pm

%files -n perl-Lim-Protocol-XMLRPC
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::RPC::Protocol::XMLRPC.3*
%{perl_vendorlib}/Lim/RPC/Protocol/XMLRPC.pm

%files -n perl-Lim-Protocol-JSONRPC
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::RPC::Protocol::JSONRPC1.3*
%{_mandir}/man3/Lim::RPC::Protocol::JSONRPC2.3*
%{perl_vendorlib}/Lim/RPC/Protocol/JSONRPC1.pm
%{perl_vendorlib}/Lim/RPC/Protocol/JSONRPC2.pm

%files -n perl-Lim-Protocol-HTTP
%defattr(-,root,root,-)
%{_mandir}/man3/Lim::RPC::Protocol::HTTP.3*
%{perl_vendorlib}/Lim/RPC/Protocol/HTTP.pm

%files -n lim-management-console-common
%defattr(-,root,root,-)
%{_datadir}/lim/html/home.html
%{_datadir}/lim/html/_css/bootstrap.min.css
%{_datadir}/lim/html/_css/application.css
%{_datadir}/lim/html/_css/prettify.css
%{_datadir}/lim/html/index.html
%{_datadir}/lim/html/_js/application.js
%{_datadir}/lim/html/_js/html5shiv.js
%{_datadir}/lim/html/_js/jquery.min.js
%{_datadir}/lim/html/_js/bootstrap.min.js
%{_datadir}/lim/html/_js/prettify.js
%{_datadir}/lim/html/_img/glyphicons-halflings-white.png
%{_datadir}/lim/html/_img/glyphicons-halflings.png

%files -n lim-management-console-agent
%defattr(-,root,root,-)
%{_datadir}/lim/html/_agent/system_information.html
%{_datadir}/lim/html/_agent/plugins.html
%{_datadir}/lim/html/_agent/index.html
%{_datadir}/lim/html/_agent/js/application.js


%pre -n lim-agentd
getent group lim >/dev/null || groupadd -r lim
getent passwd lim >/dev/null || \
    useradd -r -g lim -d / -s /sbin/nologin \
    -c "lim-agentd" lim
exit 0

%post -n lim-agentd
/sbin/chkconfig --add lim-agentd
if [ ! -f /etc/lim/ssl/private/lim-agentd.key ]; then
    openssl genrsa -out /etc/lim/ssl/private/lim-agentd.key 4096 >/dev/null 2>&1
fi &&
if [ ! -f /etc/lim/ssl/private/lim-agentd.csr ]; then
    openssl req -new -batch \
      -subj "/CN=Lim Agent Daemon/emailAddress=lim@`hostname -f`" \
      -key /etc/lim/ssl/private/lim-agentd.key \
      -out /etc/lim/ssl/private/lim-agentd.csr >/dev/null 2>&1
fi &&
if [ ! -f /etc/lim/ssl/private/lim-agentd.crt ]; then
    openssl x509 -req -days 3650 -in /etc/lim/ssl/private/lim-agentd.csr \
      -signkey /etc/lim/ssl/private/lim-agentd.key \
      -out /etc/lim/ssl/private/lim-agentd.crt >/dev/null 2>&1
fi &&
if [ ! -f /etc/lim/ssl/certs/lim-agentd.crt ]; then
    cp /etc/lim/ssl/private/lim-agentd.crt /etc/lim/ssl/certs/lim-agentd.pem \
      >/dev/null 2>&1
fi &&
c_rehash /etc/lim/ssl/certs >/dev/null 2>&1

%post -n lim-cli
if [ ! -f /etc/lim/ssl/private/lim-cli.key ]; then
    openssl genrsa -out /etc/lim/ssl/private/lim-cli.key 4096 >/dev/null 2>&1
fi &&
if [ ! -f /etc/lim/ssl/private/lim-cli.csr ]; then
    openssl req -new -batch \
      -subj "/CN=Lim CLI/emailAddress=lim@`hostname -f`" \
      -key /etc/lim/ssl/private/lim-cli.key \
      -out /etc/lim/ssl/private/lim-cli.csr >/dev/null 2>&1
fi &&
if [ ! -f /etc/lim/ssl/private/lim-cli.crt ]; then
    openssl x509 -req -days 3650 -in /etc/lim/ssl/private/lim-cli.csr \
      -signkey /etc/lim/ssl/private/lim-cli.key \
      -out /etc/lim/ssl/private/lim-cli.crt >/dev/null 2>&1
fi &&
if [ ! -f /etc/lim/ssl/certs/lim-cli.crt ]; then
    cp /etc/lim/ssl/private/lim-cli.crt /etc/lim/ssl/certs/lim-cli.pem \
      >/dev/null 2>&1
fi &&
c_rehash /etc/lim/ssl/certs >/dev/null 2>&1

%preun -n lim-agentd
if [ $1 -eq 0 ] ; then
    /sbin/service lim-agentd stop >/dev/null 2>&1
    /sbin/chkconfig --del lim-agentd
fi

%postun -n lim-agentd
if [ "$1" -ge "1" ] ; then
    /sbin/service lim-agentd condrestart >/dev/null 2>&1 || :
fi


%changelog
* Mon Apr 15 2013 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.13-1
- Release 0.13
* Tue Aug 07 2012 Jerry Lundström < lundstrom.jerry at gmail.com > - 0.12-1
- Initial package for Fedora

