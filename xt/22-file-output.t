# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the use of output files in the 'csv' and 'html' methods
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

plan(tests => 36);

my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil::Number $result;
my $x   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '9212');
my $one = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '1');
$result = $operation->division(dividend => $x, divisor => $one);

open my $fhc, '>', 'xt/data/22-step1.csv'
  or die "opening 22-step1.csv failed $!";
open my $fhh, '>', 'xt/data/22-step1.html'
  or die "opening 22-step1.html failed $!";
open my $fhl, '>', 'xt/data/22-step1.tex'
  or die "opening 22-step1.tex failed $!";

dies_ok  { $operation->csv(filehandle => $fhc, pathname => 'xt/data/22-step2.csv') } "use of both 'filehandle' and 'pathname' parameters";
dies_ok  { $operation->csv(filehandle => $fhc, pathname => 'xt/data/22-step2.csv', filemode => 'a') } "use of both 'filehandle' and 'pathname' parameters";
dies_ok  { $operation->csv(filehandle => $fhc, filemode => 'a') } "use of parameter 'filemode' without parameter 'pathname'";
dies_ok  { $operation->csv(filemode => 'a') } "use of parameter 'filemode' without parameter 'pathname'";
lives_ok { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => 'a' ) } "use of parameter 'pathname' with parameter 'filemode' = 'a'";
lives_ok { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => 'w' ) } "use of parameter 'pathname' with parameter 'filemode' = 'w'";
lives_ok { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => '>' ) } "use of parameter 'pathname' with parameter 'filemode' = '>'";
lives_ok { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => '>>') } "use of parameter 'pathname' with parameter 'filemode' = '>>'";
dies_ok  { $operation->csv(pathname => 'xt/data/22-step2.csv', filemode => 'b' ) } "wrong parameter 'filemode'";
lives_ok { $operation->csv() } "no parameters at all";
lives_ok { $operation->csv(filehandle => $fhc) } "single parameter 'filehandle'";
lives_ok { $operation->csv(pathname   => 'xt/data/22-step2.csv') } "single parameter 'pathname'";

dies_ok  { $operation->html(filehandle => $fhh, pathname => 'xt/data/22-step2.html') } "use of both 'filehandle' and 'pathname' parameters in 'html' method";
dies_ok  { $operation->html(filehandle => $fhh, pathname => 'xt/data/22-step2.html', filemode => 'a') } "use of both 'filehandle' and 'pathname' parameters in 'html' method";
dies_ok  { $operation->html(filehandle => $fhh, filemode => 'a') } "use of parameter 'filemode' without parameter 'pathname' in 'html' method";
dies_ok  { $operation->html(filemode => 'a') } "use of parameter 'filemode' without parameter 'pathname' in 'html' method";
lives_ok { $operation->html(pathname => 'xt/data/22-step2.html', filemode => 'a' ) } "use of parameter 'pathname' with parameter 'filemode' = 'a' in 'html' method";
lives_ok { $operation->html(pathname => 'xt/data/22-step2.html', filemode => 'w' ) } "use of parameter 'pathname' with parameter 'filemode' = 'w' in 'html' method";
lives_ok { $operation->html(pathname => 'xt/data/22-step2.html', filemode => '>' ) } "use of parameter 'pathname' with parameter 'filemode' = '>' in 'html' method";
lives_ok { $operation->html(pathname => 'xt/data/22-step2.html', filemode => '>>') } "use of parameter 'pathname' with parameter 'filemode' = '>>' in 'html' method";
dies_ok  { $operation->html(pathname => 'xt/data/22-step2.html', filemode => 'b' ) } "wrong parameter 'filemode' in 'html' method";
lives_ok { $operation->html() } "no parameters at all in 'html' method";
lives_ok { $operation->html(filehandle => $fhh) } "single parameter 'filehandle' in 'html' method";
lives_ok { $operation->html(pathname   => 'xt/data/22-step2.html') } "single parameter 'pathname' in 'html' method";

dies_ok  { $operation->latex(filehandle => $fhl, pathname => 'xt/data/22-step2.tex') } "use of both 'filehandle' and 'pathname' parameters in 'latex' method";
dies_ok  { $operation->latex(filehandle => $fhl, pathname => 'xt/data/22-step2.tex', filemode => 'a') } "use of both 'filehandle' and 'pathname' parameters in 'latex' method";
dies_ok  { $operation->latex(filehandle => $fhl, filemode => 'a') } "use of parameter 'filemode' without parameter 'pathname' in 'latex' method";
dies_ok  { $operation->latex(filemode => 'a') } "use of parameter 'filemode' without parameter 'pathname' in 'latex' method";
lives_ok { $operation->latex(pathname => 'xt/data/22-step2.tex', filemode => 'a' ) } "use of parameter 'pathname' with parameter 'filemode' = 'a' in 'latex' method";
lives_ok { $operation->latex(pathname => 'xt/data/22-step2.tex', filemode => 'w' ) } "use of parameter 'pathname' with parameter 'filemode' = 'w' in 'latex' method";
lives_ok { $operation->latex(pathname => 'xt/data/22-step2.tex', filemode => '>' ) } "use of parameter 'pathname' with parameter 'filemode' = '>' in 'latex' method";
lives_ok { $operation->latex(pathname => 'xt/data/22-step2.tex', filemode => '>>') } "use of parameter 'pathname' with parameter 'filemode' = '>>' in 'latex' method";
dies_ok  { $operation->latex(pathname => 'xt/data/22-step2.tex', filemode => 'b' ) } "wrong parameter 'filemode' in 'latex' method";
lives_ok { $operation->latex() } "no parameters at all in 'latex' method";
lives_ok { $operation->latex(filehandle => $fhl) } "single parameter 'filehandle' in 'latex' method";
lives_ok { $operation->latex(pathname   => 'xt/data/22-step2.tex') } "single parameter 'pathname' in 'latex' method";

close $fhc
  or die "closing 22-step1.csv failed $!";
close $fhh
  or die "closing 22-step1.html failed $!";
close $fhl
  or die "closing 22-step1.tex failed $!";

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
