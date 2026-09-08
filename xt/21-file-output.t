# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the generation of HTML on division
#
# Copyright 2023, 2024, 2026 Jean Forget
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

plan(tests => 4);

my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil::Number $result;
my $x   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '9212');
my $y   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '139');
my $one = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '1');

open my $fh, '>', 'xt/data/21-step1.csv'
  or die "opening 21-step1.csv failed $!";

$result = $operation->division(dividend => $x, divisor => $one);
$operation->csv(pathname => 'xt/data/21-step2.csv');
$operation->csv(filehandle => $fh);
is(slurp('xt/data/21-step2.csv'), slurp('xt/data/21-ref1.csv'));

$operation = Arithmetic::PaperAndPencil->new;
$result = $operation->addition($y, $one);
$operation->csv(pathname => 'xt/data/21-step2.csv', filemode => '>>');
$operation->csv(filehandle => $fh);
is(slurp('xt/data/21-step2.csv'), slurp('xt/data/21-ref2.csv'));

$operation = Arithmetic::PaperAndPencil->new;
$result = $operation->division(dividend => $y, divisor => $one);
$operation->csv(pathname => 'xt/data/21-step2.csv', filemode => 'w');
$operation->csv(filehandle => $fh);
is(slurp('xt/data/21-step2.csv'), slurp('xt/data/21-ref3.csv'));

close $fh
  or die "closing 21-step1.csv failed $!";
is(slurp('xt/data/21-step1.csv'), slurp('xt/data/21-ref4.csv'));

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
