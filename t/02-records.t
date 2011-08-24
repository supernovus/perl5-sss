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

plan tests => 12;

my $sss = SSS->new();
$sss->{debug} = 0;    ## customize this to your needs.

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

