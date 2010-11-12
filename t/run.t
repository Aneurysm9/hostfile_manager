#! /usr/bin/perl -T

use lib 't/tests';
use Test::Class::Load qw<t/tests>;

Test::Class->runtests;
