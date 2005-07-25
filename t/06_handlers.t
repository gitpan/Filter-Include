#!/usr/bin/perl

use Test::More tests => 5;

use IO::File;
use File::Spec;

use strict;
use Filter::Include (
  pre => sub {
    my($inc,$src) = @_;
    is $inc, 't/sample.pl', "Called pre source handler got filename";
    like $src, qr/test worked/, "Got the include '$inc' as expected";
  },
  post => sub {
    my($inc,$src) = @_;
    is $inc, 't/sample.pl', "Called post source handler got filename";
    like $src, qr/test worked/, "Got the include '$inc' as expected";
  },
);

no warnings 'once';
# no. 1
include 't/sample.pl';
