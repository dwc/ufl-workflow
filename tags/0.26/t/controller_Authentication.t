use strict;
use warnings;
use Test::More tests => 3;

use_ok('Catalyst::Test', 'UFL::Workflow');
use_ok('UFL::Workflow::Controller::Authentication');

my $response = request('/logout');
ok($response->is_success or $response->is_redirect, 'request for /logout');
