#!/usr/bin/perl

use warnings;
use strict;

use Module::Build;

Module::Build->new(
    dist_author => "Timothy Totten",
    module_name => 'SSS',
    license => 'artistic_2',
    requires => {
      'XML::LibXML' => 0,
      'Mouse'       => 0,
    },
    build_requires => {
      'Test::More'       => 0,
    },
    create_makefile_pl => 'traditional',
)->create_build_script;

