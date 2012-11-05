#!perl -T

use SOAP::Lite;
use Data::Dumper;
print Dumper(
    SOAP::Lite
    -> proxy('http://127.0.0.1:5353/agent')
    -> default_ns('urn:Lim::Agent::Server')
    -> call('ReadVersion')
    -> result
    );
