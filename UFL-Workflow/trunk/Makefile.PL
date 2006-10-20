use inc::Module::Install;

name     'UFL-Workflow';
all_from 'lib/UFL/Workflow.pm';

requires 'Carp';
requires 'Catalyst' => '5.7001';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Plugin::Authentication';
requires 'Catalyst::Plugin::Authentication::Store::DBIC';
requires 'Catalyst::Plugin::Authorization::ACL';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::FillInForm';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::View::TT';
requires 'Class::Accessor::Fast';
requires 'DateTime::Format::DB2';
requires 'DBD::DB2';
requires 'DBIx::Class' => '0.07000';
requires 'FormValidator::Simple';
requires 'FormValidator::Simple::ProfileManager::YAML';
requires 'Module::Find';  # For load_classes
requires 'NEXT';
requires 'Scalar::Util';
requires 'YAML';

build_requires 'Catalyst::Test';
build_requires 'Test::More';

catalyst;

install_script glob('script/*.pl');

WriteAll;
