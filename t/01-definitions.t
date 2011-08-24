#!/usr/bin/perl

## Testing the definition (.sss) parser.

use v5.10;
use strict;
use warnings;

BEGIN 
{
  unshift @INC, './lib';
}

use SSS v11.8.23; ## We need version 11.8.23 or newer.
use Test::More;

plan tests => 14;

my $sss = SSS->new();
$sss->{debug} = 2;    ## customize this to your needs.

$sss->load_defs('./t/test-defs.sss');

is $sss->get_field('date'), '2011-08-23', 'get survey-wide field'; #1

my $var1 = $sss->get_var_by_id(1);
ok defined $var1, 'get variable by id'; #2
is $var1->{name}, 'test1', 'get variable name'; #3
is $var1->{start}, 1, 'get variable start'; #4
is $var1->{finish}, 4, 'get variable finish'; #5

my @vars = $sss->get_vars();

my $count = scalar @vars;
is $count, 6, 'get ordered size'; #6

my $var2 = $sss->get_var_by_name('test2');
ok defined $var2, 'get variable by name'; #7
is $var2->{start}, 5, 'single position start'; #8
is $var2->{finish}, 5, 'single position finish'; #9
is $var2->{values}->{cats}->{1}->{text}, 'First', 'get value text'; #10

my $var3 = $vars[2]; ## arrays start from 0.
ok defined $var3, 'get variable by order'; #11
is $var3->{label}, 'Test 3', 'get variable label'; #12 
is $var3->{values}->{start}, 1, 'get value start'; #13
is $var3->{values}->{finish}, 99, 'get value finish'; #14


