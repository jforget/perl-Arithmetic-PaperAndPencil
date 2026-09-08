# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the use of output files in the 'csv' method
#
# Copyright 2026 Jean Forget
#
# This programme is free software; you can redistribute it and modify it under the Artistic License 2.0.

use 5.42.0;
use utf8;
use strict;
use warnings;
use Test::More;
use Arithmetic::PaperAndPencil;
use feature qw/class/;
use open ':encoding(UTF-8)';

BEGIN {
  eval "use Test::Exception;";
  if ($@) {
    plan skip_all => "Test::Exception needed";
    exit;
  }
}

plan(tests => 12);

my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil::Number $result;
my $x   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '9212');
my $one = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '1');
$result = $operation->division(dividend => $x, divisor => $one);

open my $fh, '>', 'xt/data/22-step1.csv'
  or die "opening 22-step1.csv failed $!";

dies_ok  { $operation->csv(filehandle => $fh, pathname => 'xt/data/22-step2.csv') } "use of both 'filehandle' and 'pathname' parameters";
dies_ok  { $operation->csv(filehandle => $fh, pathname => 'xt/data/22-step2.csv', filemode => 'a') } "use of both 'filehandle' and 'pathname' parameters";
dies_ok  { $operation->csv(filehandle => $fh, filemode => 'a') } "use of parameter 'filemode' without parameter 'pathname'";
dies_ok  { $operation->csv(filemode => 'a') } "use of parameter 'filemode' without parameter 'pathname'";
lives_ok { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => 'a' ) } "use of parameter 'filemode' with parameter 'pathname' = 'a'";
lives_ok { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => 'w' ) } "use of parameter 'filemode' with parameter 'pathname' = 'w'";
lives_ok { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => '>' ) } "use of parameter 'filemode' with parameter 'pathname' = '>'";
lives_ok { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => '>>') } "use of parameter 'filemode' with parameter 'pathname' = '>>'";
dies_ok  { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => 'b' ) } "wrong parameter 'filemode'";
lives_ok { $operation->csv() } "no parameters at all";
lives_ok { $operation->csv(filehandle => $fh) } "single parameter 'filehandle'";
lives_ok { $operation->csv(pathname   => 'xt/data/22-step2.csv') } "single parameter 'pathname'";

close $fh
  or die "closing 22-step1.csv failed $!";

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
