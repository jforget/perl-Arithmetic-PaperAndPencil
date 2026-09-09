# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking use of output files in the 'csv' and 'html' methods
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

plan(tests => 8);

my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil::Number $result;
my $x   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '9212');
my $y   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '139');
my $one = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '1');

open my $fhc, '>', 'xt/data/21-step1.csv'
  or die "opening 21-step1.csv failed $!";
open my $fhh, '>', 'xt/data/21-step1.html'
  or die "opening 21-step1.html failed $!";

# A bit of pedagogy within the tests
print $fhh <<'EOF';
<html>
<head><title>Examples of computations</title></head>
<body>
EOF

$result = $operation->division(dividend => $x, divisor => $one);
$operation->csv( pathname   => 'xt/data/21-step2.csv');
$operation->html(pathname   => 'xt/data/21-step2.html');
$operation->csv( filehandle => $fhc);
$operation->html(filehandle => $fhh);
is(slurp('xt/data/21-step2.csv' ), slurp('xt/data/21-ref1.csv'));
is(slurp('xt/data/21-step2.html'), slurp('xt/data/21-ref1.html'));

$operation = Arithmetic::PaperAndPencil->new;
$result = $operation->addition($y, $one);
$operation->csv( pathname   => 'xt/data/21-step2.csv' , filemode => '>>');
$operation->html(pathname   => 'xt/data/21-step2.html', filemode => '>>');
$operation->csv( filehandle => $fhc);
$operation->html(filehandle => $fhh);
is(slurp('xt/data/21-step2.csv' ), slurp('xt/data/21-ref2.csv' ));
is(slurp('xt/data/21-step2.html'), slurp('xt/data/21-ref2.html'));

$operation = Arithmetic::PaperAndPencil->new;
$result = $operation->division(dividend => $y, divisor => $one);
$operation->csv( pathname   => 'xt/data/21-step2.csv' , filemode => 'w');
$operation->html(pathname   => 'xt/data/21-step2.html', filemode => 'w');
$operation->csv( filehandle => $fhc);
$operation->html(filehandle => $fhh);
is(slurp('xt/data/21-step2.csv' ), slurp('xt/data/21-ref3.csv' ));
is(slurp('xt/data/21-step2.html'), slurp('xt/data/21-ref3.html'));

print $fhh "</body>\n</html>\n";

close $fhc
  or die "closing 21-step1.csv failed $!";
close $fhh
  or die "closing 21-step1.html failed $!";
is(slurp('xt/data/21-step1.csv' ), slurp('xt/data/21-ref4.csv'));
is(slurp('xt/data/21-step1.html'), slurp('xt/data/21-ref4.html'));

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
