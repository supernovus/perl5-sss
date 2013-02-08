#!/usr/bin/perl

## Testing the definition (.sss) parser.

use v5.10;
use strict;
use warnings;

BEGIN 
{
  unshift @INC, './lib';
}

use SSS v11.9.19; ## Minimum version
use Test::More;

plan tests => 15;

my $sss = SSS->new();

$sss->load_defs(file=>'./t/test-defs.sss');

is $sss->defs->date, '2011-08-23', 'get survey-wide field'; #1

my $var1 = $sss->defs->get_var_by_id(1);
ok defined $var1, 'get variable by id'; #2
is $var1->name, 'test1', 'get variable name'; #3
is $var1->position_start, 1, 'get variable start'; #4
is $var1->position_end, 4, 'get variable finish'; #5

my @vars = @{$sss->vars};

my $count = scalar @vars;
is $count, 6, 'get ordered size'; #6

my $var2 = $sss->defs->get_var_by_name('test2');
ok defined $var2, 'get variable by name'; #7
is $var2->position_start, 5, 'single position start'; #8
is $var2->position_end, 5, 'single position finish'; #9
is $var2->values_by_id->{1}->label, 'First', 'get value by id label'; #10
is $var2->values->[1]->label, 'Second', 'get value by order label'; #11

my $var3 = $vars[2]; ## arrays start from 0.
ok defined $var3, 'get variable by order'; #12
is $var3->label, 'Test 3', 'get variable label'; #13
is $var3->range_start, 1, 'get value start'; #14
is $var3->range_end, 99, 'get value finish'; #15

