use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Lim',
    AUTHOR              => q{Jerry Lundström <lundstrom.jerry@gmail.com>},
    VERSION_FROM        => 'lib/Lim.pm',
    ABSTRACT_FROM       => 'lib/Lim.pm',
    EXE_FILES           => [ 'bin/lim-agentd',
                             'bin/lim-cli' ],
    (! eval { ExtUtils::MakeMaker->VERSION(6.46) } ? () :
        (META_ADD => {
            resources => {
                homepage   => 'http://github.com/jelu/lim/wiki',
                repository => 'http://github.com/jelu/lim',
                bugtracker => 'http://github.com/jelu/lim/issues',
            },
        })
    ),
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Lim-*' },
    PMLIBDIRS => [ 'lib' ],
    PM => {
'lib/Lim.pm' => '$(INST_LIBDIR)/Lim.pm',
'lib/XMLRPC/Transport/HTTP/Server.pm' => '$(INST_LIBDIR)/XMLRPC/Transport/HTTP/Server.pm',
'lib/Lim/Agent.pm' => '$(INST_LIBDIR)/Lim/Agent.pm',
'lib/Lim/CLI.pm' => '$(INST_LIBDIR)/Lim/CLI.pm',
'lib/Lim/Plugins.pm' => '$(INST_LIBDIR)/Lim/Plugins.pm',
'lib/Lim/RPC.pm' => '$(INST_LIBDIR)/Lim/RPC.pm',
'lib/Lim/Util.pm' => '$(INST_LIBDIR)/Lim/Util.pm',
'lib/Lim/Agent/CLI.pm' => '$(INST_LIBDIR)/Lim/Agent/CLI.pm',
'lib/Lim/Agent/Client.pm' => '$(INST_LIBDIR)/Lim/Agent/Client.pm',
'lib/Lim/Agent/Server.pm' => '$(INST_LIBDIR)/Lim/Agent/Server.pm',
'lib/Lim/Component/CLI.pm' => '$(INST_LIBDIR)/Lim/Component/CLI.pm',
'lib/Lim/Component/Client.pm' => '$(INST_LIBDIR)/Lim/Component/Client.pm',
'lib/Lim/Component/Server.pm' => '$(INST_LIBDIR)/Lim/Component/Server.pm',
'lib/Lim/Component.pm' => '$(INST_LIBDIR)/Lim/Component.pm',
'lib/Lim/Error.pm' => '$(INST_LIBDIR)/Lim/Error.pm',
'lib/Lim/RPC/Client.pm' => '$(INST_LIBDIR)/Lim/RPC/Client.pm',
'lib/Lim/RPC/Call.pm' => '$(INST_LIBDIR)/Lim/RPC/Call.pm',
'lib/Lim/RPC/Callback/JSONRPC.pm' => '$(INST_LIBDIR)/Lim/RPC/Callback/JSONRPC.pm',
'lib/Lim/RPC/Callback/XMLRPC.pm' => '$(INST_LIBDIR)/Lim/RPC/Callback/XMLRPC.pm',
'lib/Lim/RPC/Callback/SOAP.pm' => '$(INST_LIBDIR)/Lim/RPC/Callback/SOAP.pm',
'lib/Lim/RPC/Callback/JSON.pm' => '$(INST_LIBDIR)/Lim/RPC/Callback/JSON.pm',
'lib/Lim/RPC/Value.pm' => '$(INST_LIBDIR)/Lim/RPC/Value.pm',
'lib/Lim/RPC/Server/Client.pm' => '$(INST_LIBDIR)/Lim/RPC/Server/Client.pm',
'lib/Lim/RPC/Server.pm' => '$(INST_LIBDIR)/Lim/RPC/Server.pm',
'lib/Lim/DB/Schema.pm' => '$(INST_LIBDIR)/Lim/DB/Schema.pm',
'lib/Lim/Plugin/SoftHSM.pm' => '$(INST_LIBDIR)/Lim/Plugin/SoftHSM.pm',
'lib/Lim/Plugin/OpenDNSSEC/CLI.pm' => '$(INST_LIBDIR)/Lim/Plugin/OpenDNSSEC/CLI.pm',
'lib/Lim/Plugin/OpenDNSSEC/Client.pm' => '$(INST_LIBDIR)/Lim/Plugin/OpenDNSSEC/Client.pm',
'lib/Lim/Plugin/OpenDNSSEC/Server.pm' => '$(INST_LIBDIR)/Lim/Plugin/OpenDNSSEC/Server.pm',
'lib/Lim/Plugin/SoftHSM/CLI.pm' => '$(INST_LIBDIR)/Lim/Plugin/SoftHSM/CLI.pm',
'lib/Lim/Plugin/SoftHSM/Client.pm' => '$(INST_LIBDIR)/Lim/Plugin/SoftHSM/Client.pm',
'lib/Lim/Plugin/SoftHSM/Server.pm' => '$(INST_LIBDIR)/Lim/Plugin/SoftHSM/Server.pm',
'lib/Lim/Plugin/OpenDNSSEC.pm' => '$(INST_LIBDIR)/Lim/Plugin/OpenDNSSEC.pm',
'lib/Lim/DB.pm' => '$(INST_LIBDIR)/Lim/DB.pm',
'lib/Log/Log4perl/Appender/Lim/CLI.pm' => '$(INST_LIBDIR)/Log/Log4perl/Appender/Lim/CLI.pm',
}
);
