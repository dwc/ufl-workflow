use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', 'UFL::Workflow');

ok(request('/')->is_success);
