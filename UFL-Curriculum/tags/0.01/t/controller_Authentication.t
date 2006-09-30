use strict;
use warnings;
use Test::More tests => 3;

use_ok('Catalyst::Test', 'UFL::Curriculum');
use_ok('UFL::Curriculum::Controller::Authentication');

my $response = request('/logout');
ok($response->is_success or $response->is_redirect, 'request for /logout');
