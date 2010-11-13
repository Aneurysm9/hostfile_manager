#! /usr/bin/perl -T

use strict;
use warnings;

use lib 't/tests';
use Test::Class::Load qw<t/tests>;

Test::Class->runtests;
