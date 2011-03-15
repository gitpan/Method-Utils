use strict;
use warnings;

use Module::Build;

my $build = Module::Build->new(
   module_name => 'Method::Utils',
   build_requires => {
      'Test::More' => 0,
   },
   license => 'perl',
   create_makefile_pl => 'traditional',
   create_license => 1,
   create_readme  => 1,
);

$build->create_build_script;