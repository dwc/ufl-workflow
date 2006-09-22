use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'UFL::Curriculum' }
BEGIN { use_ok 'UFL::Curriculum::Controller::Auth' }

ok( request('/auth')->is_success, 'Request should succeed' );


