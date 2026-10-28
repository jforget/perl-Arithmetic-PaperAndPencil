# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the iron division
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

plan(tests => 16);

my $refcsv  = slurp('xt/data/24-iron-div.csv' );
my $refhtml = slurp('xt/data/24-iron-div.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil::Number $result;
my $x1 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '7825');
my $y1 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '43');
my $x2 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '35500');
my $y2 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '113');
my $x3 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '284000');
my $y3 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '904');
my $x4 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '142000');
my $y4 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '452');
my $x5 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '284000');
my $y5 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '9');
my $x6 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '296789');
my $y6 = Arithmetic::PaperAndPencil::Number->new(radix => 10, value => '986');

check($x1, $y1,   '181',  '42', 0);
check($x2, $y2,   '314',  '18', 0);
check($x3, $y3,   '314', '144', 0);
check($x4, $y4,   '314',  '72', 0);
check($x5, $y5, '31555',   '5', 0);
check($x1, $y1,   '181',  '42', 1);
check($x6, $y6,   '301',   '3', 1);

is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 4);
is($html, $refhtml, "Checking HTML file");

sub check($dvd, $dvr, $quotient, $remainder, $compact = 0) {
  my Arithmetic::PaperAndPencil::Number $q;
  my Arithmetic::PaperAndPencil::Number $r;
  ($q, $r) = $operation->division(dividend => $dvd, divisor => $dvr, type => 'iron', result => 'both', compact => $compact);
  is($q->value, $quotient , "quotient is $quotient");
  is($r->value, $remainder, "remainder is $remainder");
}

sub slurp($fname) {
  open my $f, '<', $fname
    or die "Opening $fname $!";
  $/ = undef;
  my $result = <$f>;
  close $f
    or die "Closing $fname $!";
  return $result;
}
