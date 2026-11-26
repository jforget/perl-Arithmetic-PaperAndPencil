# -*- encoding: utf-8; indent-tabs-mode: nil -*-
#
# Checking the light radix conversions
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

my @tests = ( [ qw<10   628  8 1164> ]
            , [ qw< 8  4025 10 2069> ]
            , [ qw<16   3E8 10 1000> ]
            , [ qw<16   FA0 10 4000> ]
            , [ qw< 8    12 10   10> ]
            );
plan(tests => 2 + 2 * @tests);

my $refcsv  = slurp('xt/data/25-conversion-light.csv' );
my $refhtml = slurp('xt/data/25-conversion-light.html');
my Arithmetic::PaperAndPencil $operation = Arithmetic::PaperAndPencil->new;
my Arithmetic::PaperAndPencil $dummy_op  = Arithmetic::PaperAndPencil->new;

for my $data (@tests) {
  my ($old_radix, $nb1, $new_radix, $expected) = @$data;
  check_cnv($old_radix,  $nb1, $new_radix, $expected);
}
is($operation->csv, $refcsv, "Checking CSV file");
my $html = $operation->html(lang => 'fr', silent => 0, level => 3);
is($html, $refhtml, "Checking HTML file");
done_testing;

sub check_cnv($old_radix, $nb1, $new_radix, $expected) {

  my $old  = Arithmetic::PaperAndPencil::Number->new(radix => $old_radix, value => $nb1);
  my Arithmetic::PaperAndPencil::Number $result;
  $result = $operation->conversion(number => $old, radix => $new_radix, type => 'light', mult_and_sub => 'separate');
  is($result->value, $expected, "$nb1 (radix $old_radix) converts to @{[$result->value]} (radix $new_radix)");
  $result = $operation->conversion(number => $old, radix => $new_radix, type => 'light', mult_and_sub => 'combined');
  is($result->value, $expected, "$nb1 (radix $old_radix) converts to @{[$result->value]} (radix $new_radix)");

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
