use inc::Module::Install;

name 'UFL-Curriculum';
all_from 'lib/UFL/Curriculum.pm';

requires 'Catalyst' => '5.7001';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'YAML';

build_requires 'Catalyst::Test';
build_requires 'Test::More';

catalyst;

install_script glob('script/*.pl');

WriteAll;
