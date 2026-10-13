# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the skipping of zero digits in additions
#
# Copyright 2024, 2026 Jean Forget
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

my $refcsv;
my $refhtml;
my $fcsv  = 'xt/data/23-skip-zero.csv';
my $fhtml = 'xt/data/23-skip-zero.html';
open my $f1, '<', $fcsv  or die "opening $fcsv $!";
open my $f2, '<', $fhtml or die "opening $fhtml $!";
{ local $/ = undef;
  $refcsv  = <$f1>;
  $refhtml = <$f2>;
}
close $f1 or die "closing $fcsv $!";
close $f2 or die "closing $fhtml $!";

my $operation = Arithmetic::PaperAndPencil->new;
my @list =  qw/ 2200022121
                2220122010
                2200022001
                2200022010  /;
my $result = '101221112212';
my @numbers;

# using radix 3 to have "big" carries (that is, carries with 2 digits or more)
for my $ch (@list) {
  my $x =  Arithmetic::PaperAndPencil::Number->new(value => $ch, radix => 3);
  push(@numbers, $x);
}

my $sum = $operation->addition1(numbers => \@numbers, skip_zero => 0);
is($sum->value, $result, "Checking the sum keeping the zero digits");
$sum    = $operation->addition1(numbers => \@numbers, skip_zero => 1);
is($sum->value, $result, "Checking the sum skipping the zero digits");

is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 3, css => {});
is($html, $refhtml, "Checking HTML file");

