use strict;
use warnings;
use Test::More tests => 2;

use_ok('Catalyst::Test', 'UFL::Curriculum');

ok(request('/')->is_success);
