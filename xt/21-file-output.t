# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking use of output files in the 'csv', 'html' and 'latex' methods
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

plan(tests => 12);

my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil::Number $result;
my $x   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '9212');
my $y   = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '139');
my $one = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '1');

open my $fhc, '>', 'xt/data/21-step1.csv'
  or die "opening 21-step1.csv failed $!";
open my $fhh, '>', 'xt/data/21-step1.html'
  or die "opening 21-step1.html failed $!";
open my $fhl, '>', 'xt/data/21-step1.tex'
  or die "opening 21-step1.tex failed $!";

# A bit of pedagogy within the tests
print $fhh <<'EOF';
<html>
<head><title>Examples of computations</title></head>
<body>
EOF

print $fhl <<'EOF';
% -*- encoding: utf-8 -*-
\documentclass[a4paper]{article}
\usepackage{luamplib}
\parindent=0mm
\begin{document}
EOF

$result = $operation->division(dividend => $x, divisor => $one);
$operation->csv( pathname   => 'xt/data/21-step2.csv');
$operation->html(pathname   => 'xt/data/21-step2.html');
$operation->latex(pathname   => 'xt/data/21-step2.tex');
$operation->csv( filehandle => $fhc);
$operation->html(filehandle => $fhh);
$operation->latex(filehandle => $fhl, suppress_header => 1);
is(slurp('xt/data/21-step2.csv' ), slurp('xt/data/21-ref1.csv'));
is(slurp('xt/data/21-step2.html'), slurp('xt/data/21-ref1.html'));
is(slurp('xt/data/21-step2.tex' ), slurp('xt/data/21-ref1.tex'));

$operation = Arithmetic::PaperAndPencil->new;
$result = $operation->addition($y, $one);
$operation->csv( pathname   => 'xt/data/21-step2.csv' , filemode => '>>');
$operation->html(pathname   => 'xt/data/21-step2.html', filemode => '>>');
$operation->latex(pathname   => 'xt/data/21-step2.tex' , filemode => '>>', suppress_header => 1);
$operation->csv( filehandle => $fhc);
$operation->html(filehandle => $fhh);
$operation->latex(filehandle => $fhl, suppress_header => 1);
is(slurp('xt/data/21-step2.csv' ), slurp('xt/data/21-ref2.csv' ));
is(slurp('xt/data/21-step2.html'), slurp('xt/data/21-ref2.html'));
is(slurp('xt/data/21-step2.tex' ), slurp('xt/data/21-ref2.tex' ));

$operation = Arithmetic::PaperAndPencil->new;
$result = $operation->division(dividend => $y, divisor => $one);
$operation->csv( pathname   => 'xt/data/21-step2.csv' , filemode => 'w');
$operation->html(pathname   => 'xt/data/21-step2.html', filemode => 'w');
$operation->latex(pathname   => 'xt/data/21-step2.tex', filemode => 'w');
$operation->csv( filehandle => $fhc);
$operation->html(filehandle => $fhh);
$operation->latex(filehandle => $fhl, suppress_header => 1);
is(slurp('xt/data/21-step2.csv' ), slurp('xt/data/21-ref3.csv' ));
is(slurp('xt/data/21-step2.html'), slurp('xt/data/21-ref3.html'));
is(slurp('xt/data/21-step2.tex' ), slurp('xt/data/21-ref3.tex' ));

print $fhh "</body>\n</html>\n";

print $fhl <<'EOF';
\end{document}
EOF

close $fhc
  or die "closing 21-step1.csv failed $!";
close $fhh
  or die "closing 21-step1.html failed $!";
close $fhl
  or die "closing 21-step1.tex failed $!";
is(slurp('xt/data/21-step1.csv' ), slurp('xt/data/21-ref4.csv'));
is(slurp('xt/data/21-step1.html'), slurp('xt/data/21-ref4.html'));
is(slurp('xt/data/21-step1.tex' ), slurp('xt/data/21-ref4.tex' ));

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
