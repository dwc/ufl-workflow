use inc::Module::Install;

name     'UFL-Workflow';
all_from 'lib/UFL/Workflow.pm';

requires 'Carp';
requires 'Catalyst' => '5.7006';
requires 'Catalyst::Action::RenderView';
requires 'Catalyst::Authentication::Store::DBIx::Class' => '0.102';
requires 'Catalyst::Model::DBIC::Schema';
requires 'Catalyst::Model::LDAP';
requires 'Catalyst::Plugin::Authentication' => '0.10003';
requires 'Catalyst::Plugin::Authorization::ACL';
requires 'Catalyst::Plugin::Authorization::Roles';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::FillInForm';
requires 'Catalyst::Plugin::Session';
requires 'Catalyst::Plugin::Session::State::Cookie';
requires 'Catalyst::Plugin::Session::Store::File';
requires 'Catalyst::Plugin::Setenv';
requires 'Catalyst::Plugin::StackTrace';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Plugin::Unicode::Encoding';
requires 'Catalyst::View::Email' => '0.02';
requires 'Catalyst::View::JSON';
requires 'Catalyst::View::TT';
requires 'Class::C3' => '0.12';  # For next::can
requires 'DateTime::Format::DB2' => '0.05';
requires 'DBD::DB2';
requires 'DBIx::Class' => '0.07000';
requires 'Digest::MD5';
requires 'File::stat';
requires 'FormValidator::Simple';
requires 'FormValidator::Simple::ProfileManager::YAML';
requires 'Getopt::Long';
requires 'MIME::Type';
requires 'MIME::Types';
requires 'Module::Find';
requires 'Scalar::Util';
requires 'Template::Plugin::Textile';
requires 'Template::Plugin::Wrap';
requires 'YAML';

build_requires 'Catalyst::Test';
build_requires 'DBD::SQLite';
build_requires 'Test::More';
build_requires 'Test::YAML::Valid';

catalyst;

install_script glob('script/*.pl');

WriteAll;
