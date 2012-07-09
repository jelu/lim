#!perl -T

use XMLRPC::Lite;
print XMLRPC::Lite
    -> proxy('https://localhost:5353/agent.xmlrpc')
    -> call('version')
    -> result;
