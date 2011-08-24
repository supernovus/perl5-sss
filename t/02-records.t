#!/usr/bin/perl

## Testing the records parser.

use v5.10;
use strict;
use warnings;

BEGIN 
{
  unshift @INC, './lib';
}

use SSS;
use Test::More;

plan tests => 36;

my $sss = SSS->new();
$sss->{debug} = 1;    ## customize this to your needs.

$sss->load_defs('./t/test-defs.sss');
$sss->load_recs('./t/test-records.asc');

## Test the basic tables.
my @recs = $sss->get_recs_by_name();
is $recs[0]->{test1}->{value}, 'HELP', 'get variable value by name (1)'; #1
is $recs[0]->{test2}->{value}, 1, 'get variable value by name (2)'; #2
is $recs[0]->{test3}->{value}, 23, 'get variable value by name (3)'; #3
is $recs[1]->{test1}->{value}, 'TEST', 'get variable value by name (4)'; #4
is $recs[1]->{test2}->{value}, 2, 'get variable value by name (5)'; #5
is $recs[1]->{test3}->{value}, 41, 'get variable value by name (6)'; #6
is $recs[2]->{test1}->{value}, 'BLOT', 'get variable value by name (7)'; #7
is $recs[2]->{test2}->{value}, 3, 'get variable value by name (8)'; #8
is $recs[2]->{test3}->{value}, 87, 'get variable value by name (9)'; #9

## Okay, now test get_recs_by_id(), just for completion.
my @recs2 = $sss->get_recs_by_id();
is $recs2[0]->{1}->{value}, 'HELP', 'get variable value by id (1)'; #10
is $recs2[1]->{2}->{value}, 2, 'get variable value by id (2)'; #11
is $recs2[2]->{3}->{value}, 87, 'get variable value by id (3)'; #12

## Okay, now let's test text labels.
is $recs[0]->{test2}->{text}, 'First',  'get variable text (1)'; #13
is $recs[1]->{test2}->{text}, 'Second', 'get variable text (2)'; #14
is $recs[2]->{test2}->{text}, 'Third',  'get variable text (3)'; #15

## Okay, let's get some MULTIPLE records in Bitstring format.
my $multi1 = $recs[0]->{test4}->{values};
is $multi1->{1}->{value}, 0, 'get bitstring MULTI (1)'; #16
is $multi1->{2}->{value}, 0, 'get bitstring MULTI (2)'; #17
is $multi1->{3}->{value}, 0, 'get bitstring MULTI (3)'; #18
my $multi2 = $recs[1]->{test4}->{values};
is $multi2->{1}->{value}, 0, 'get bitstring MULTI (4)'; #19
is $multi2->{2}->{value}, 1, 'get bitstring MULTI (5)'; #20
is $multi2->{3}->{value}, 0, 'get bitstring MULTI (6)'; #21
my $multi3 = $recs[2]->{test4}->{values};
is $multi3->{1}->{value}, 0, 'get bitstring MULTI (7)'; #22
is $multi3->{2}->{value}, 1, 'get bitstring MULTI (8)'; #23
is $multi3->{3}->{value}, 1, 'get bitstring MULTI (9)'; #24

## Now, let's get some MULTIPLE records in SPREAD format.
my $multi4 = $recs[0]->{test5}->{values};
is $multi4->{1}->{value}, 1, 'get SPREAD MULTI (1)'; #25
is $multi4->{5}->{value}, 1, 'get SPREAD MULTI (2)'; #26
is $multi4->{15}->{value}, 0, 'get SPREAD MULTI (3)'; #27
is $multi4->{26}->{value}, 0, 'get SPREAD MULTI (4)'; #28
my $multi5 = $recs[1]->{test5}->{values};
is $multi5->{1}->{value}, 0, 'get SPREAD MULTI (5)'; #29
is $multi5->{5}->{value}, 0, 'get SPREAD MULTI (6)'; #30
is $multi5->{15}->{value}, 1, 'get SPREAD MULTI (7)'; #31
is $multi5->{26}->{value}, 1, 'get SPREAD MULTI (8)'; #32

## And some MULTIPLE records in SPREAD format with implied width.
my $multi6 = $recs[0]->{test6}->{values};
is $multi6->{1}->{value}, 0, 'get implicit SPREAD MULTI (1)'; #33
is $multi6->{2}->{value}, 1, 'get implicit SPREAD MULTI (2)'; #34
my $multi7 = $recs[1]->{test6}->{values};
is $multi7->{1}->{value}, 1, 'get implicit SPREAD MULTI (3)'; #35
is $multi7->{2}->{value}, 0, 'get implicit SPREAD MULTI (4)'; #36

