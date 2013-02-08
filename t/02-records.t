#!/usr/bin/perl

## Testing the records parser.

use v5.10;
use strict;
use warnings;

BEGIN 
{
  unshift @INC, './lib';
}

use SSS v13;
use Test::More;

plan tests => 34;

my $sss = SSS->new();

$sss->load_defs(file=>'./t/test-defs.sss');
$sss->load_recs(file=>'./t/test-records.asc');

## For our tests, we're going to get record fields indexed by name.
my @recs = $sss->recs->get_fields_by_name();
is $recs[0]->{test1}->value, 'HELP', 'get variable value by name (1)'; #1
is $recs[0]->{test2}->value, 1, 'get variable value by name (2)'; #2
is $recs[0]->{test3}->value, 23, 'get variable value by name (3)'; #3
is $recs[1]->{test1}->value, 'TEST', 'get variable value by name (4)'; #4
is $recs[1]->{test2}->value, 2, 'get variable value by name (5)'; #5
is $recs[1]->{test3}->value, 41, 'get variable value by name (6)'; #6
is $recs[2]->{test1}->value, 'BLOT', 'get variable value by name (7)'; #7
is $recs[2]->{test2}->value, 3, 'get variable value by name (8)'; #8
is $recs[2]->{test3}->value, 87, 'get variable value by name (9)'; #9

## Okay, now test getting the fields by id.
my @recs2 = $sss->recs->get_fields_by_id();
is $recs2[0]->{1}->value, 'HELP', 'get variable value by id (1)'; #10
is $recs2[1]->{2}->value, 2, 'get variable value by id (2)'; #11
is $recs2[2]->{3}->value, 87, 'get variable value by id (3)'; #12

## Okay, now let's test text labels.
is $recs[0]->{test2}->label, 'First',  'get variable text (1)'; #13
is $recs[1]->{test2}->label, 'Second', 'get variable text (2)'; #14
is $recs[2]->{test2}->label, 'Third',  'get variable text (3)'; #15

## Okay, let's get some MULTIPLE records in Bitstring format.
my $multi1 = $recs[0]->{test4}->values_by_id;
is $multi1->{1}->value, 0, 'get bitstring MULTI (1)'; #16
is $multi1->{2}->value, 0, 'get bitstring MULTI (2)'; #17
is $multi1->{3}->value, 0, 'get bitstring MULTI (3)'; #18
my $multi2 = $recs[1]->{test4}->values_by_id;
is $multi2->{1}->value, 0, 'get bitstring MULTI (4)'; #19
is $multi2->{2}->value, 1, 'get bitstring MULTI (5)'; #20
is $multi2->{3}->value, 0, 'get bitstring MULTI (6)'; #21
my $multi3 = $recs[2]->{test4}->values;
is $multi3->[0]->value, 0, 'get ordered bitstring MULTI (1)'; #22
is $multi3->[1]->value, 1, 'get ordered bitstring MULTI (2)'; #23
is $multi3->[2]->value, 1, 'get ordered bitstring MULTI (3)'; #24

## Now, let's get some MULTIPLE records in SPREAD format.
my $multi4 = $recs[0]->{test5}->values_by_id;
is $multi4->{1}->value, 1, 'get SPREAD MULTI (1)'; #25
is $multi4->{5}->value, 1, 'get SPREAD MULTI (2)'; #26
is $multi4->{15}->value, 0, 'get SPREAD MULTI (3)'; #27
is $multi4->{26}->value, 0, 'get SPREAD MULTI (4)'; #28
my $multi5 = $recs[1]->{test5}->values;
is $multi5->[0]->value, 15, 'get ordered SPREAD MULTI (1)'; #29
is $multi5->[1]->value, 26, 'get ordered SPREAD MULTI (2)'; #30

## And some MULTIPLE records in SPREAD format with implied width.
my $multi6 = $recs[0]->{test6}->values_by_id;
is $multi6->{1}->value, 0, 'get implicit SPREAD MULTI (1)'; #31
is $multi6->{2}->value, 1, 'get implicit SPREAD MULTI (2)'; #32
my $multi7 = $recs[1]->{test6}->values;
is $multi7->[0]->value, 1, 'get ordered implicit SPREAD MULTI (1)'; #33
is $multi7->[1]->value, 0, 'get ordered implicit SPREAD MULTI (2)'; #34

