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

plan tests => 16;

my $sss = SSS->new();

$sss->load_defs(file=>'./t/test-defs.xml');

is $sss->defs->date, '2013-02-12', 'get survey-wide field'; #1

is $sss->defs->survey_name, 'TestSurvey', 'survey name field'; #2

my $var1 = $sss->defs->get_var_by_id(1);
ok defined $var1, 'get variable by id'; #3
is $var1->name, 'test1', 'get variable name'; #4
is $var1->position_start, 1, 'get variable start'; #5
is $var1->position_end, 4, 'get variable finish'; #6

my @vars = @{$sss->vars};

my $count = scalar @vars;
is $count, 6, 'get ordered size'; #7

my $var2 = $sss->defs->get_var_by_name('test2');
ok defined $var2, 'get variable by name'; #8
is $var2->position_start, 5, 'single position start'; #9
is $var2->position_end, 5, 'single position finish'; #10
is $var2->values_by_id->{1}->label, 'First', 'get value by id label'; #11
is $var2->values->[1]->label, 'Second', 'get value by order label'; #12

my $var3 = $vars[2]; ## arrays start from 0.
ok defined $var3, 'get variable by order'; #13
is $var3->label, 'Test 3', 'get variable label'; #14
is $var3->range_start, 1, 'get value start'; #15
is $var3->range_end, 99, 'get value finish'; #16

