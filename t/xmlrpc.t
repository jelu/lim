#!perl -T

use XMLRPC::Lite;
use Data::Dumper;
print Dumper(
    XMLRPC::Lite
    -> proxy('https://127.0.0.1:5353/agent')
    -> call('Lim::Agent::Server.ReadVersion')
    -> result
    );
