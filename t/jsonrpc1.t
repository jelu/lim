#!perl -T

use JSON::XS;
use LWP::UserAgent;
use Data::Dumper;

$req = HTTP::Request->new(GET => 'http://127.0.0.1:5353/agent');
$req->content_type('application/json');
$req->content(JSON::XS->new->ascii->encode({
    method => 'ReadVersion',
    id => 1
}));

$res = LWP::UserAgent->new->request($req);

if ($res->is_success) {
    print Dumper(JSON::XS->new->ascii->decode($res->content));
}
