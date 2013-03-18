use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'DBIx::Object',
    license             => 'perl',
    dist_author         => 'Desmond Daignault <nawglan@gmail.com>',
    dist_version_from   => 'lib/DBIx/Object.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'DBIx::Object-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
