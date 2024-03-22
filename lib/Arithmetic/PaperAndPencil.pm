# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use 5.38.0;
use utf8;
use strict;
use warnings;
use open ':encoding(UTF-8)';
use feature      qw/class/;
use experimental qw/class/;
use Arithmetic::PaperAndPencil::Action;
use Arithmetic::PaperAndPencil::Char;
use Arithmetic::PaperAndPencil::Label;

class Arithmetic::PaperAndPencil 0.01;

use Arithmetic::PaperAndPencil::Number qw/max_unit adjust_sub/;

use Carp;
use Exporter 'import';
use POSIX qw/floor/;
use List::Util qw/min max/;

field @action;

method from_csv {
  my ($csv) = @_;
  @action = ();
  for my $line (split("\n", $csv)) {
    my $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'dummy');
    $action->from_csv($line);
    push @action, $action;
  }
}

method csv {
  my $result = join "\n", map { $_->csv } @action;
  if (substr($result, -1, 1) ne "\n") {
    $result .= "\n";
  }
  return $result;
}

method html(%param) {
  my $lang   = $param{lang}   // 'fr';
  my $silent = $param{silent} // 0;
  my $level  = $param{level}  // 3;
  my $css    = $param{css};
  my $talkative = 1 - $silent; # "silent" better for API, "talkative" better for programming
  my $result    = '';
  my @sheet     = ();
  my %vertical_lines = ();
  my %cache_l2p_col  = ();
  my $c_min     = 0;
  my $l_min     = 0;

  # checking the minimum line number
  my sub check_l_min($l) {
    if ($l < $l_min) {
      # inserting new empty lines before the existing ones
      for ($l .. $l_min - 1) {
        unshift @sheet, [];
      }
      # updating the line minimum number
      $l_min = $l;
    }
  }
  # logical to physical line number
  my sub l2p_lin($logl) {
    my $result = $logl - $l_min;
    return $result;
  }

  # checking the minimum column number
  my sub check_c_min($c) {
    if ($c < $c_min) {
      my $delta_c = $c_min - $c;
      for my $line (@sheet) {
        for (1 .. $delta_c) {
          unshift @$line, Arithmetic::PaperAndPencil::Char->space_char;
        }
      }
      $c_min = $c;
      %cache_l2p_col  = ();
    }
  }
  # logical to physical column number
  my sub l2p_col($logc) {
    if ($cache_l2p_col{$logc}) {
      return $cache_l2p_col{$logc};
    }
    my $result = $logc - $c_min;
    for my $col (keys %vertical_lines) {
      if ($logc > $col) {
        ++$result;
      }
    }
    $cache_l2p_col{$logc} = $result;
    return $result;
  }

  my sub filling_spaces($l, $c) {
    # putting spaces into all uninitialised boxes
    for my $l1 (0 .. l2p_lin($l)) {
      $sheet[$l1][0] //= Arithmetic::PaperAndPencil::Char->space_char;
    }
    for my $c1 (0 .. l2p_col($c)) {
      $sheet[l2p_lin($l)][$c1] //= Arithmetic::PaperAndPencil::Char->space_char;
    }
  }

  for my $action (@action) {
    if ($action->label =~ /^TIT/ or $action->label eq 'NXP01') {
      @sheet          = ();
      %vertical_lines = ();
      %cache_l2p_col  = ();
      $c_min          = 0;
      $l_min          = 0;
    }

    # Drawing a vertical line
    if ($action->label eq 'DRA01') {
      if  ($action->w1c != $action->w2c) {
        die "The line is not vertical, starting at column ", $action->w1c, " and ending at column ", $action->w2c;
      }
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_l_min($action->w2l);
      check_c_min($action->w1c);
      # making some clear space for the vertical line
      unless ($vertical_lines{$action->w1c}) {
        $vertical_lines{$action->w1c} = 1;
        # clearing the cache
        %cache_l2p_col  = ();

        # shifting characters past the new vertical line's column
        for my $l (0 .. $#sheet) {
          for my $c (0 .. l2p_col($action->w1c)) {
             $sheet[$l][$c] //= Arithmetic::PaperAndPencil::Char->space_char;
          }
          my $line = $sheet[$l];
          splice(@$line, l2p_col($action->w1c) + 1, 0, Arithmetic::PaperAndPencil::Char->space_char);
          $sheet[$l] = $line;
        }
      }
      # making the vertical line
      for my $l ($action->w1l .. $action->w2l) {
        filling_spaces($l, $action->w1c);
        $sheet[l2p_lin($l)][l2p_col($action->w1c) + 1] = Arithmetic::PaperAndPencil::Char->pipe_char;
      }
    }

    # drawing an horizontal line or drawing a hook over a dividend
    my sub draw_h($at, $from, $to) {
      # checking the line and column minimum numbers
      check_l_min($at);
      check_c_min($from);
      check_c_min($to);
      # begin and end
      my ($c_beg, $c_end);
      if ($from > $to) {
        $c_beg = l2p_col($to);
        $c_end = l2p_col($from);
        filling_spaces($at, $from);
      }
      else {
        $c_beg = l2p_col($from);
        $c_end = l2p_col($to);
        filling_spaces($at, $to);
      }
      for my $i ($c_beg .. $c_end) {
        $sheet[l2p_lin($at)][$i]->set_underline(1);
      }
    }

    # Drawing an horizontal line
    if ($action->label eq 'DRA02') {
      if ($action->w1l != $action->w2l) {
        die "The line is not horizontal, starting at line {$action->w1l} and ending at line {$action->w2l}";
      }
      draw_h($action->w1l, $action->w1c, $action->w2c);
    }

    # Drawing a hook over a dividend (that is, an horizontal line above)
    if ($action->label eq 'HOO01') {
      if  ($action->w1l != $action->w2l) {
        die "The hook is not horizontal, starting at line {$action->w1l} and ending at line {$action->w2l}";
      }
      draw_h($action->w1l - 1, $action->w1c, $action->w2c);
    }

    # Drawing an oblique line
    if ($action->label eq 'DRA03') {
      if ($action->w2c - $action->w1c != $action->w2l - $action->w1l) {
        die "The line is not oblique";
      }
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_l_min($action->w2l);
      check_c_min($action->w1c);
      check_c_min($action->w2c);
      # begin and end
      my ($l_beg, $c_beg);
      if ($action->w2l > $action->w1l) {
        # line is defined top-left to bot-right
        $l_beg = $action->w1l;
        $c_beg = $action->w1c;
      }
      else {
        # line was defined bot-right to top-left
        $l_beg = $action->w2l;
        $c_beg = $action->w2c;
      }
      # drawing the line top-left to bot-right
      for my $i (0 .. abs($action->w2l - $action->w1l)) {
        filling_spaces($l_beg + $i, $c_beg + $i);
        my $l1 = l2p_lin($l_beg + $i);
        my $c1 = l2p_col($c_beg + $i);
        $sheet[$l1][$c1]->set_char('\\');
        # the line
        #   $sheet[$l1; $c1] = backslash_char->char;
        # would be wrong, because in some cases it would clobber the "underline" attribute of an already existing char
      }
    }
    if ($action->label eq 'DRA04') {
      if ($action->w2c - $action->w1c != $action->w1l - $action->w2l) {
        die "The line is not oblique";
      }
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_l_min($action->w2l);
      check_c_min($action->w1c);
      check_c_min($action->w2c);
      # begin and end
      my ($l_beg, $c_beg);
      if ($action->w2l > $action->w1l) {
        # line is defined top-right to bot-left
        $l_beg = $action->w1l;
        $c_beg = $action->w1c;
      }
      else {
        # line was defined bot-left to top-right
        $l_beg = $action->w2l;
        $c_beg = $action->w2c;
      }
      # drawing the line top-right to bot-left
      for my $i (0 .. abs($action->w2l - $action->w1l)) {
        filling_spaces($l_beg + $i, $c_beg - $i);
        my $l1 = l2p_lin($l_beg + $i);
        my $c1 = l2p_col($c_beg - $i);
        $sheet[$l1][$c1]->set_char('/');
        # the line
        #   $sheet[$l1; $c1] = slash_char();
        # would be wrong, because in some cases it would clobber the "underline" attribute of an already existing char
      }
    }

    # Reading some digits (or other characters) and possibly striking them
    if ($action->r1val ne '') {

      # checking the line and column minimum numbers
      # (should not be necessary: if the digits are being read, they must have been previously written)
      check_l_min($action->r1l);
      check_c_min($action->r1c - length($action->r1val) + 1);

      # putting spaces into all uninitialised boxes
      # (should not be necessary, for the same reason)
      filling_spaces($action->r1l, $action->r1c);

      # tagging each char
      for my $i (0 .. length($action->r1val) - 1) {
         my $str = substr($action->r1val, $i, 1);
         for ($sheet[l2p_lin($action->r1l)][l2p_col($action->r1c - length($action->r1val) + $i + 1)]) {
           $_->set_read(1);
           if ($action->r1str) {
             $_->set_strike(1);
           }
         }
      }
    }
    if ($action->r2val ne '') {

      # checking the line and column minimum numbers
      # (should not be necessary, for the same reason as r1val)
      check_l_min($action->r2l);

      # putting spaces into all uninitialised boxes
      # (should not be necessary, for the same reason)
      filling_spaces($action->r2l, $action->r2c);

      # tagging each char
      for my $i (0 .. length($action->r2val) - 1) {
         my $str = substr($action->r2val, $i, 1);
         for ($sheet[l2p_lin($action->r2l)][l2p_col($action->r2c - length($action->r2val) + $i + 1)]) {
           $_->set_read(1);
           if ($action->r2str) {
             $_->set_strike(1);
           }
         }
      }
    }

    # Writing some digits (or other characters)
    if ($action->w1val ne '') {
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_c_min($action->w1c - length($action->w1val) + 1);
      # putting spaces into all uninitialised boxes
      filling_spaces($action->w1l, $action->w1c);
      # putting each char separately into its designated box
      for my $i (0 .. length($action->w1val) - 1) {
         my $str = substr($action->w1val, $i, 1);
         for ($sheet[l2p_lin($action->w1l)][l2p_col($action->w1c - length($action->w1val) + $i + 1)]) {
           $_->set_char($str);
           $_->set_write(1);
         }
      }
    }
    if ($action->w2val ne '') {
      # checking the line and column minimum numbers
      check_l_min($action->w2l);
      check_c_min($action->w2c - length($action->w2val) + 1);
      # putting spaces into all uninitialised boxes
      filling_spaces($action->w2l, $action->w2c);
      # putting each char separately into its designated box
      for my $i (0 .. length($action->w2val) - 1) {
         my $str = substr($action->w2val, $i, 1);
         for ($sheet[l2p_lin($action->w2l)][l2p_col($action->w2c - length($action->w2val) + $i + 1)]) {
           $_->set_char($str);
           $_->set_write(1);
         }
      }
    }

    # Erasing characters
    if ($action->label eq 'ERA01') {
      if ($action->w1l != $action->w2l) {
        die "The chars are not horizontally aligned, starting at line {$action->w1l} and ending at line {$action->w2l}";
      }
      # checking the line and column minimum numbers
      check_l_min($action->w1l);
      check_c_min($action->w1c);
      check_c_min($action->w2c);
      # begin and end
      my ($c_beg, $c_end);
      if ($action->w1c > $action->w2c) {
        $c_beg = l2p_col($action->w2c);
        $c_end = l2p_col($action->w1c);
        filling_spaces($action->w1l, $action->w1c);
      }
      else {
        $c_beg = l2p_col($action->w1c);
        $c_end = l2p_col($action->w2c);
        filling_spaces($action->w1l, $action->w2c);
      }
      for my $i ($c_beg .. $c_end) {
        $sheet[l2p_lin($action->w1l)][$i]->set_char(' ');
      }
    }

    # Talking
    if ($talkative or substr($action->label, 0, 3) eq 'TIT') {
      my $line = Arithmetic::PaperAndPencil::Label::full_label($action->label, $action->val1, $action->val2, $action->val3, $lang);
      if ($line) {
        if (substr($action->label, 0, 3) eq 'TIT') {
          $line = "<operation>$line</operation>\n";
        }
        else {
          $line = "<talk>$line</talk>\n";
        }
        $result .= $line;
      }
    }

    # Showing the operation
    if ($action->level <= $level) {
      my $op = '';
      for my $l (0 .. $#sheet) {
        my $line  = $sheet[$l];
        my $line1 = join('', map { $_->pseudo_html } @$line);
        $op .= $line1 . "\n";
      }
      if ($op ne '') {
        $result .= "<pre>\n$op</pre>\n";
      }
      # untagging written and read chars
      for my $line (@sheet) {
        for my $char (@$line) {
          $char->set_read (0);
          $char->set_write(0);
        }
      }
    }
  }

  # simplyfing pseudo-HTML
  $result =~ s{</underline><underline>}{}g;
  $result =~ s{</strike><strike>}{}g;
  $result =~ s{</write>(\h*)<write>}{$1}g;
  $result =~ s{</read>(\h*)<read>}{$1}g;

  # changing pseudo-HTML into proper HTML
  $result =~ s/operation>/h1>/g;
  if ($css->{talk}) {
    $result =~ s!</talk>!</p>!g;
    $result =~ s!<talk>!<p class='$css->{talk}'>!g;
  }
  else {
    $result =~ s/talk>/p>/g;
  }
  if ($css->{underline}) {
    $result =~ s!</underline>!</span>!g;
    $result =~ s!<underline>!<span class='$css->{underline}'>!g;
  }
  else {
    $result =~ s/underline>/u>/g;
  }
  # maybe I should replace all "strike" tags by "del"? or by "s"?
  # see https://www.w3schools.com/tags/tag_strike.asp : <strike> is not supported in HTML5
  if ($css->{strike}) {
    $result =~ s!</strike>!</span>!g;
    $result =~ s!<strike>!<span class='$css->{strike}'>!g;
  }
  if ($css->{read}) {
    $result =~ s!</read>!</span>!g;
    $result =~ s!<read>!<span class='$css->{read}'>!g;
  }
  else {
    $result =~ s/read>/em>/g;
  }
  if ($css->{write}) {
    $result =~ s!</write>!</span>!g;
    $result =~ s!<write>!<span class='$css->{write}'>!g;
  }
  else {
    $result =~ s/write>/strong>/g;
  }
  $result =~ s/\h+$//gm;

  return $result;
}

method addition(@numbers) {
  if (@numbers == 0) {
    croak "The addition needs at least one number to add";
  }

  my $action;
  my $nb         = 0+ @numbers;
  my $radix      = $numbers[0]->radix;
  my $max_length = 0;
  my @digits; # storing the numbers' digits
  my @total;  # storing the total's digit positions

  $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => "TIT01", val1 => "$radix");
  push @action, $action;

  for my $i (0 .. $#numbers) {
    my $n = $numbers[$i];
    # checking the number
    if ($n->radix != $radix) {
      croak "All numbers must have the same radix";
    }
    # writing the number
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => $i, w1c => 0, w1val => $n->value);
    push(@action, $action);
    # preparing the horizontal line
    if ($max_length < $n->chars) {
      $max_length = $n->chars;
    }
    # feeding the table of digits
    my $val = reverse($n->value);
    for my $j (0 .. length($val) - 1) {
      my $x = substr($val, $j, 1);
      push(@{$digits[$j]}, { lin => $i, col => -$j, val => $x } );
    }
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => 2, label => 'DRA02', w1l => $nb - 1, w1c => 1 - $max_length
                                                                                , w2l => $nb - 1, w2c => 0);
  push(@action, $action);
  for my $j (0 .. $max_length -1) {
    $total[$j] = { lin => $nb, col => -$j };
  }
  my $result = $self->_adding(\@digits, \@total, 0, $radix);
  return Arithmetic::PaperAndPencil::Number->new(value => $result, radix => $radix);
}

method subtraction(%param) {
  my $high = $param{high};
  my $low  = $param{low};
  my $type = $param{type}  // 'std';

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $high->radix;
  my $leng  = $high->chars;
  if ($low->radix != $radix) {
    croak "The two numbers have different bases: $radix != @{[$low->radix]}";
  }
  if ($type ne 'std' && $type ne 'compl') {
    croak "Subtraction type '$type' unknown";
  }
  if ($high < $low) {
    croak "The high number @{[$high->value]} must be greater than or equal to the low number @{[$low->value]}";
  }
  if (@action) {
    $action[-1]->set_level(0);
  }
  if (($type eq 'std')) {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'TIT02', val1 => $high->value, val2 => $low->value, val3 => $radix);
    push(@action, $action);
    # set-up
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 0, w1c => $leng, w1val => $high->value);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 1, w1c => $leng, w1val => $low->value);
    push(@action, $action);

    # computation
    my $result = '';
    $result = $self->_embedded_sub(basic_level => 0, l_hi => 0, c_hi => $leng, high => $high
                                                   , l_lo => 1, c_lo => $leng, low  => $low
                                                   , l_re => 2, c_re => $leng);
    $action[-1]->set_level(0);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
  else {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 9, label => 'TIT15', val1 => $high->value, val2 => $low->value, val3 => $radix);
    push(@action, $action);
    my Arithmetic::PaperAndPencil::Number $complement = $low->complement($leng);
    # set-up
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                                   , label => 'SUB03', val1 => $radix, val2 => $low->value, val3  => $complement->value
                                                     , w1l  => 0     , w1c  => $leng      , w1val => $high->value
                                                     , w2l  => 1     , w2c  => $leng      , w2val => $complement->value);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 2, label => 'DRA02', w1l => 1, w1c => 1
                                               , w2l => 1, w2c => $leng);
    push(@action, $action);

    my @digits; # storing the numbers' digits
    my @result; # storing the result's digit positions
    my $compl_val = '0' x ($leng - $complement->chars) . $complement->value;
    for my $i (0 .. $leng - 1) {
      $digits[$i][0] = { lin => 0, col => $leng - $i, val => substr($high->value, $leng - $i - 1, 1) };
      $digits[$i][1] = { lin => 1, col => $leng - $i, val => substr($compl_val  , $leng - $i - 1, 1) };
      $result[$i]    = { lin => 2, col => $leng - $i };
    }
    my $result = substr($self->_adding(\@digits, \@result, 0, $radix), 1);
    # getting rid of leading zeroes except if the result is zero
    $result =~ s/^0*//;
    if ($result eq '') {
      $result = '0';
    }
    $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'SUB04', val1 => $result, r1l => 2, r1c => 0, r1val => '1', r1str => 1);
    push(@action, $action);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
}

method multiplication(%param) {
  my $multiplicand = $param{multiplicand};
  my $multiplier   = $param{multiplier};
  my $type         = $param{type}         // 'std';
  my $direction    = $param{direction}    // 'ltr';        # for the 'boat' type, elementary products are processed left-to-right or right-to-left ('rtl')
  my $mult_and_add = $param{mult_and_add} // 'separate';   # for the 'boat' type, addition is a separate subphase (contrary: 'combined')
  my $product      = $param{product}      // 'L-shaped';   # for the 'jalousie-?" types, the product is L-shaped along the rectangle (contrary: 'straight' on the bottom line)

  my Arithmetic::PaperAndPencil::Action $action;
  if ($multiplicand->radix != $multiplier->radix) {
    die "Multiplicand and multiplier have different bases: @{[$multiplicand->radix]} != @{[$multiplier->radix]}";
  }
  my $title = '';
  my $radix = $multiplicand->radix;
  if    ($type eq 'std'       ) { $title = 'TIT03' ; }
  elsif ($type eq 'shortcut'  ) { $title = 'TIT04' ; }
  elsif ($type eq 'prepared'  ) { $title = 'TIT05' ; }
  elsif ($type eq 'jalousie-A') { $title = 'TIT06' ; }
  elsif ($type eq 'jalousie-B') { $title = 'TIT07' ; }
  elsif ($type eq 'boat'      ) { $title = 'TIT08' ; }
  elsif ($type eq 'russian'   ) { $title = 'TIT19' ; }
  if ($title eq '') {
    die "Multiplication type '$type' unknown";
  }
  if ($type eq 'jalousie-A' || $type eq 'jalousie-B') {
    if ($product ne 'L-shaped' && $product ne 'straight') {
      die "Product shape '$product' should be 'L-shaped' or 'straight'";
    }
  }
  if ($type eq 'boat') {
    if ($direction ne 'ltr' && $direction ne 'rtl') {
      die "Direction '$direction' should be 'ltr' (left-to-right) or 'rtl' (right-to-left)";
    }
    if ($mult_and_add ne 'separate' && $mult_and_add ne 'combined') {
      die "Parameter mult_and_add '$mult_and_add' should be 'separate' or 'combined'";
    }
  }

  my $len1 = $multiplicand->chars;
  my $len2 = $multiplier->chars;
  if (@action) {
    $action[-1]->set_level(0);
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => 9
               , label => $title
               , val1  => $multiplicand->value
               , val2  => $multiplier->value
               , val3  => $multiplier->radix
               );
  push(@action, $action);

  # caching the partial products for prepared and shortcut multiplications
  my %mult_cache = (1 => $multiplicand);
  if ($type eq 'prepared') {
    my $limit = max(split('', $multiplier->value));
    $self->_preparation(factor => $multiplicand, limit => $limit, cache => %mult_cache);
  }

  if ($type eq 'std' || $type eq  'shortcut' || $type eq 'prepared') {
    # set-up
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                          , label => 'WRI00', w1l => 0, w1c => $len1 + $len2, w1val => $multiplicand->value
                                            , w2l => 1, w2c => $len1 + $len2, w2val => $multiplier->value);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 2
                          , label => 'DRA02', w1l => 1, w1c => min($len1, $len2)
                                            , w2l => 1, w2c => $len1 + $len2);
    push(@action, $action);

    # multiplication of two single-digit numbers
    if ($len1 == 1 && $len2 == 1) {
      my Arithmetic::PaperAndPencil::Number $pdt = $multiplier * $multiplicand;
      $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'MUL02'
                   , r1l => 0, r1c => 2, r1val => $multiplier->value   , val1 => $multiplier->value
                   , r2l => 1, r2c => 2, r2val => $multiplicand->value , val2 => $multiplicand->value
                   , w1l => 2, w1c => 2, w1val => $pdt->value          , val3 => $pdt->value
                   );
      push(@action, $action);
      return $pdt;
    }
    # multiplication with a single-digit multiplier
    if ($len2 == 1 && $type eq 'prepared') {
      my Arithmetic::PaperAndPencil::Number $pdt;
      $pdt = $mult_cache{$multiplier->value};
      $action = Arithmetic::PaperAndPencil::Action->new(level => 0, label => 'WRI05', val1 => $pdt->value
                   , w1l => 2, w1c => $len1 + 1, w1val => $pdt->value
                   );
      push(@action, $action);
      return $pdt;
    }
    if ($len2 == 1) {
      my Arithmetic::PaperAndPencil::Number $pdt;
      $pdt = $self->_simple_mult(basic_level => 0, l_md => 0, c_md => $len1 + 1, multiplicand => $multiplicand
                                                 , l_mr => 1, c_mr => $len1 + 1, multiplier   => $multiplier
                                                 , l_pd => 2, c_pd => $len1 + 1 );
      $action[-1]->set_level(0);
      return $pdt;
    }
    # multiplication with a multi-digit multiplier
    my Arithmetic::PaperAndPencil::Number $pdt;
    $pdt = $self->_adv_mult(basic_level => 0, l_md => 0, c_md => $len1 + $len2, multiplicand => $multiplicand
                                            , l_mr => 1, c_mr => $len1 + $len2, multiplier   => $multiplier
                                            , l_pd => 2, c_pd => $len1 + $len2
                                            , type => $type, cache => \%mult_cache);
    $action[-1]->set_level(0);
    return $pdt;
  }
  if ($type eq 'jalousie-A' || $type eq 'jalousie-B') {
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                          , label => 'DRA02', w1l => 0, w1c => 1
                                            , w2l => 0, w2c => 2 * $len1);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                  , label => 'DRA01', w1l => 1        , w1c => 0
                                    , w2l => 2 * $len2, w2c => 0);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                  , label => 'DRA01', w1l => 1        , w1c => 2 * $len1
                                    , w2l => 2 * $len2, w2c => 2 * $len1);
    push(@action, $action);
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                  , label => 'DRA02', w1l => 2 * $len2, w1c => 1
                                    , w2l => 2 * $len2, w2c => 2 * $len1);
    push(@action, $action);
  }
  if ($type eq 'jalousie-A') {
    for my $i (1 .. $len1) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 0, w1c => 2 * $i - 1, w1val => substr($multiplicand->value, $i - 1, 1));
      push(@action, $action);
    }
    for my $i (1 .. $len2) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 2 * $i, w1c => 2 * $len1 + 1, w1val => substr($multiplier->value, $i - 1, 1));
      push(@action, $action);
    }
    for my $i (1 .. $len1 + $len2 - 1) {
      my $l1 = 1;
      my $c1 = 2 * $i;
      my $l2 = 2 * $len2;
      my $c2 = 2 * ($i - $len2) + 1;
      if ($c1 >= 2 * $len1) {
        $l1 += $c1 - 2 * $len1;
        $c1  = 2 * $len1;
      }
      if ($c2 <= 0 && $product eq 'L-shaped') {
        $l2 -= 1 - $c2;
        $c2  = 1;
      }
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA04', w1l => $l1, w1c => $c1, w2l => $l2, w2c => $c2);
      push(@action, $action);
    }
    # end of set-up phase
    $action[-1]->set_level(2);

    # multiplication phase
    my @partial;
    for my $l (1 .. $len2) {
      my $x = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplier->value, $l - 1, 1));
      for my $c (1 .. $len1) {
        my $y = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplicand->value, $c - 1, 1));
        my Arithmetic::PaperAndPencil::Number $pdt   = $x * $y;
        my Arithmetic::PaperAndPencil::Number $unit  = $pdt->unit;
        my Arithmetic::PaperAndPencil::Number $carry = $pdt->carry;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                     , label => 'MUL01', r1l => 2 * $l    , r1c => 2 * $len1 + 1, r1val => $x->value    , val1 => $x->value
                                       , r2l => 0         , r2c => 2 * $c - 1   , r2val => $y->value    , val2 => $y->value
                                       , w1l => 2 * $l - 1, w1c => 2 * $c - 1   , w1val => $carry->value, val3 => $pdt->value
                                       , w2l => 2 * $l    , w2c => 2 * $c       , w2val => $unit->value
                                       );
        push(@action, $action);
        $partial[$len1 + $len2 - $l - $c    ][2 * $l    ] = { lin => 2 * $l    , col => 2 * $c    , val => $unit->value };
        $partial[$len1 + $len2 - $l - $c + 1][2 * $l - 1] = { lin => 2 * $l - 1, col => 2 * $c - 1, val => $carry->value };
      }
      # end of line
      $action[-1]->set_level(3);
    }
    # end of multiplication phase
    $action[-1]->set_level(2);

    # Addition phase
    my @final;
    my $limit;
    if    ($product eq 'L-shaped') { $limit = $len1;         }
    elsif ($product eq 'straight') { $limit = $len1 + $len2; }
    for my $i (0 .. $limit - 1) {
      $final[$i] = { lin => 2 * $len2 + 1, col => 2 * ($len1 - $i) - 1 };
    }
    for my $i ($limit .. $len1 + $len2 - 1) {
      $final[$i] = { lin => 2 * ($len1 + $len2 - $i), col => 0 };
    }
    my $result = $self->_adding(\@partial, \@final, 0, $radix);
    $action[-1]->set_level(0);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
  if ($type eq 'jalousie-B') {
    for my $i (1 .. $len1) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 0, w1c => 2 * $i, w1val => substr($multiplicand->value, $i - 1, 1));
      push(@action, $action);
    }
    for my $i (1 .. $len2) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'WRI00', w1l => 2 * ($len2 - $i + 1), w1c => 0, w1val => substr($multiplier->value, $i - 1, 1));
      push(@action, $action);
    }
    for my $i (1 - $len2 .. $len1 - 1) {
      my $l1 = 1;
      my $c1 = 1 + 2 * $i;
      my $l2 = 2 * $len2;
      my $c2 = 2 * ($i + $len2);
      if ($c1 <= 0) {
        $l1 += 1 - $c1;
        $c1  = 1;
      }
      if ($c2 >= 2 * $len1 && $product eq 'L-shaped') {
        $l2 -= $c2 - 2 * $len1;
        $c2  = 2 * $len1;
      }
      $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'DRA03', w1l => $l1, w1c => $c1, w2l => $l2, w2c => $c2);
      push(@action, $action);
    }
    # end of set-up phase
    $action[-1]->set_level(2);

    # multiplication phase
    my @partial;
    for my $l (1 .. $len2) {
      my $x = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplier->value, $len2 - $l, 1));
      for my $c (1 .. $len1) {
        my $y = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplicand->value, $c - 1, 1));
        my Arithmetic::PaperAndPencil::Number $pdt   = $x * $y;
        my Arithmetic::PaperAndPencil::Number $unit  = $pdt->unit;
        my Arithmetic::PaperAndPencil::Number $carry = $pdt->carry;
        $action = Arithmetic::PaperAndPencil::Action->new(level => 5
                     , label => 'MUL01', r1l => 2 * $l    , r1c => 0         , r1val => $x->value    , val1 => $x->value
                                       , r2l => 0         , r2c => 2 * $c    , r2val => $y->value    , val2 => $y->value
                                       , w1l => 2 * $l    , w1c => 2 * $c - 1, w1val => $carry->value, val3 => $pdt->value
                                       , w2l => 2 * $l - 1, w2c => 2 * $c    , w2val => $unit->value
                                       );
        push(@action, $action);
        $partial[$len1 - $c + $l - 1][2 * $l - 1] = { lin => 2 * $l - 1, col => 2 * $c    , val => $unit->value };
        $partial[$len1 - $c + $l    ][2 * $l    ] = { lin => 2 * $l    , col => 2 * $c - 1, val => $carry->value };
      }
      # end of line
      $action[-1]->set_level(3);
    }
    # end of multiplication phase
    $action[-1]->set_level(2);

    # Addition phase
    my @final;
    my $limit;
    if    ($product eq 'L-shaped') { $limit = $len2; }
    elsif ($product eq 'straight') { $limit = 0;     }
    for my $i (0 .. $limit - 1) {
      $final[$i] = { lin => 2 * $i + 2, col => 2 * $len1 + 1 };
    }
    for my $i ($limit .. $len1 + $len2 - 1) {
      $final[$i] = { lin => 2 * $len2 + 1, col => 2 * ($len1 + $len2 - $i) };
    }
    my $result = $self->_adding(\@partial, \@final, 0, $radix);
    $action[-1]->set_level(0);
    return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
  }
my $result = '0';
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
}

method _adding($digits, $pos, $basic_level, $radix, $striking = 0) {
  my @digits = @$digits;
  my @pos    = @$pos;
  my $action;
  my $sum;
  my $result = '';
  my $carry  = 0;

  for my $i (0 .. $#digits) {
    my $l = $digits[$i];
    my @l = grep { $_ } @$l; # removing empty entries
    if (0+ @l == 0) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => 'WRI04'           , val1  => $carry
                                                                  , w1l => $pos[$i]{lin}, w1c => $pos[$i]{col}, w1val => $carry
                                                                  );
      push(@action, $action);
      $result = $carry . $result;
    }
    elsif (0+ @l == 1 && $carry eq '0') {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3
                          , label => 'WRI04'                          , val1  => $l[0]{val}
                          , r1l => $l[ 0  ]{lin}, r1c => $l[ 0  ]{col}, r1val => $l[0]{val}, r1str => $striking
                          , w1l => $pos[$i]{lin}, w1c => $pos[$i]{col}, w1val => $l[0]{val}
                          );
      push(@action, $action);
      $result = $l[0]{val} . $result;
    }
    else {
      my $first;
      $sum = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $l[0]{val});
      if ($carry eq '0') {
        $sum   += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $l[1]{val});
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6
                            , label => 'ADD01' , val1  => $l[0]{val}, val2  => $l[1]{val}, val3  => $sum->value
                            , r1l => $l[0]{lin}, r1c   => $l[0]{col}, r1val => $l[0]{val}, r1str => $striking
                            , r2l => $l[1]{lin}, r2c   => $l[1]{col}, r2val => $l[1]{val}, r2str => $striking
                            );
        $first = 2;
      }
      else {
        $sum   += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6
                            , label => 'ADD01'   , val1 => $l[0]{val}, val2  => $carry    , val3  => $sum->value
                            , r1l   => $l[0]{lin}, r1c  => $l[0]{col}, r1val => $l[0]{val}, r1str => $striking
                            );
        $first = 1;
      }
      push(@action, $action);
      for my $j ($first .. $#l) {
        $sum   += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $l[$j]{val});
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6
                          , label => 'ADD02'    , val1 => $l[$j]{val}, val2  => $sum->value
                          , r1l   => $l[$j]{lin}, r1c  => $l[$j]{col}, r1val => $l[$j]{val}, r1str => $striking
                          );
        push(@action, $action);
      }
      if ($i == @digits - 1) {
        my $last_action = pop(@action);
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 2
                          , label => $last_action->label, val1  => $last_action->val1, val2   => $last_action->val2 , val3  => $last_action->val3
                          , r1l   => $last_action->r1l  , r1c   => $last_action->r1c , r1val  => $last_action->r1val, r1str => $striking
                          , r2l   => $last_action->r2l  , r2c   => $last_action->r2c , r2val  => $last_action->r2val, r2str => $striking
                          , w1l   => $pos[$i]{lin}      , w1c   => $pos[$i]{col}     ,  w1val => $sum->value
                          );
        push(@action, $action);
        $result = $sum->value . $result;
      }
      else {
        my $digit = $sum->unit->value;
        $carry    = $sum->carry->value;
        my $lin;
        my $col;
        my $code = 'WRI02';
        if ($carry eq '0') {
          $code = 'WRI03';
        }
        $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3
                            , label => $code        , val1 => $digit       , val2 => $carry
                            , w1l   => $pos[$i]{lin}, w1c  => $pos[$i]{col}, w1val => $digit
                             );
        push(@action, $action);
        $result = $digit . $result;
      }
    }
  }
  return $result;
}

method _embedded_sub(%param) {
  my $basic_level = $param{basic_level};
  my $l_hi        = $param{l_hi};
  my $c_hi        = $param{c_hi};
  my $high        = $param{high};
  my $l_lo        = $param{l_lo};
  my $c_lo        = $param{c_lo};
  my $low         = $param{low};
  my $l_re        = $param{l_re};
  my $c_re        = $param{c_re};

  my Arithmetic::PaperAndPencil::Action $action;
  my $radix = $high->radix;
  my $leng  = $high->chars;
  # set-up
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 2, label => 'DRA02', w1l => $l_lo, w1c => $c_lo - $leng + 1
                                                            , w2l => $l_lo, w2c => $c_lo);
  push(@action, $action);

  my $carry  = '0';
  my $result = '';
  my $label;

  # First subphase, looping over the low number's digits
  for my $i (0 .. $low->chars - 1) {
    my $high1 = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($high->value, $leng      - $i - 1, 1));
    my $low1  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($low->value, $low->chars - $i - 1, 1));
    my $adj1;
    my $res1;
    my $low2;
    if ($carry eq '0') {
      ($adj1, $res1) = adjust_sub($high1, $low1);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'SUB01', val1  => $low1->value, val2 => $res1->value, val3 => $adj1->value
                   , r1l => $l_hi, r1c => $c_hi - $i, r1val => $high1->value
                   , r2l => $l_lo, r2c => $c_lo - $i, r2val => $low1->value
                   );
    }
    else {
      $low2 = $low1 + Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'ADD01'   , val1  => $low1->value, val2 => $carry, val3 => $low2->value
                   , r1l => $l_lo, r1c => $c_lo - $i, r1val => $low1->value
                   );
      push(@action, $action);
      ($adj1, $res1) = adjust_sub($high1, $low2);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'SUB02'   , val1  => $res1->value, val2 => $adj1->value
                   , r1l => $l_hi, r1c => $c_hi - $i, r1val => $high1->value
                   );
    }
    push(@action, $action);
    $result = $res1->unit->value . $result;
    $carry  = $adj1->carry->value;
    if ($carry eq '0') {
      $label = 'WRI03';
    }
    else {
      $label = 'WRI02';
    }
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => $label    , val1  => $res1->unit->value, val2 => $carry
                                                    , w1l   => $l_re           , w1c   => $c_re - $i, w1val => $res1->unit->value
                                                    );
    push(@action, $action);
  }
  # Second subphase, dealing with the carry
  my $pos = $low->chars;
  while ($carry ne '0') {
    my $high1   = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($high->value, $leng - $pos - 1, 1));
    my $carry1  = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
    my $adj1;
    my $res1;
    ($adj1, $res1) = adjust_sub($high1, $carry1);
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'SUB01', val1  => $carry, val2 => $res1->value, val3 => $adj1->value
                 , r1l => $l_hi, r1c => $c_hi - $pos, r1val => $high1->value
                 );
    push(@action, $action);
    $result = $res1->unit->value . $result;
    $carry  = $adj1->carry->value;
    if ($carry eq '0') {
      $label = 'WRI03';
    }
    else {
      $label = 'WRI02';
    }
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => $label      , val1  => $res1->unit->value, val2 => $carry
                                                    , w1l   => $l_re           , w1c   => $c_re - $pos, w1val => $res1->unit->value
                                                    );
    # no need to write the final zero if there is no carry
    if ($res1->unit->value ne '0' or $carry ne '0' or $pos < $leng - 1) {
      push(@action, $action);
    }
    $pos++;
  }
  # Third subphase, a single copy
  if ($pos < $leng) {
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level, label => 'WRI05'     , val1  => substr($high->value, 0, $leng - $pos)
                                                      , w1l   => $l_re       , w1c   => $c_re - $pos, w1val => substr($high->value, 0, $leng - $pos)
                                                    );
    push(@action, $action);
    $result = substr($high->value, 0, $leng - $pos) . $result;
  }

  return $result;
}

method _adv_mult(%param) {
  my $basic_level  = $param{basic_level};
  my $type         = $param{type} // 'std';
  my $l_md         = $param{l_md}; # coordinates of the multiplicand
  my $c_md         = $param{c_md};
  my $l_mr         = $param{l_mr}; # coordinates of the multiplier
  my $c_mr         = $param{c_mr};
  my $l_pd         = $param{l_pd}; # coordinates of the product
  my $c_pd         = $param{c_pd};
  my %cache        = %{$param{cache}};
  my $multiplicand = $param{multiplicand};
  my $multiplier   = $param{multiplier};

  my Arithmetic::PaperAndPencil::Action $action;
  my $result     = '';
  my $radix      = $multiplier->radix;
  my $line       = $l_pd;
  my $pos        = $multiplier->chars - 1;
  my $shift      = 0;
  my $shift_char = '0';
  my @partial; # storing the partial products' digits
  my @final  ; # storing the final product's digit positions

  while ($pos >= 0) {
    # shifting the current simple multiplication because of embedded zeroes
    if (substr($multiplier->value, 0, $pos + 1) =~ /(0+)$/) {
      $shift += length($1);
      $pos   -= length($1);
    }
    if ($shift != 0) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => 'WRI00', w1l => $line, w1c => $c_pd, w1val => $shift_char x $shift);
      push(@action, $action);
      if ($shift_char eq '0') {
        for my $i (0 .. $shift - 1) {
          push @{$partial[$i]}, { lin => $line, col => $c_pd - $i, val => '0'};
        }
      }
    }
    # computing the simple multiplication
    my $mul = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplier->value, $pos, 1));
    my Arithmetic::PaperAndPencil::Number $pdt;
    if ($type ne 'std' && $cache{$mul->value}) {
      $pdt = $cache{$mul->value};
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => 'WRI05', val1 => $pdt->value
                                                             , w1l => $line, w1c => $c_pd - $shift, w1val => $pdt->value
                                                             );
      push(@action, $action);

    }
    else {
      $pdt = $self->_simple_mult(basic_level => $basic_level
                            , l_md => $l_md, c_md => $c_md         , multiplicand => $multiplicand
                            , l_mr => $l_mr, c_mr => $c_mr - $shift, multiplier   => $mul
                            , l_pd => $line, c_pd => $c_pd - $shift);
      # filling the cache
      $cache{$mul->value} = $pdt;
    }
    # storing the digits of $pdt
    my @digit_list = reverse(split('', $pdt->value));
    for my $i (0 .. $#digit_list) {
      my $x = $digit_list[$i];
      push @{$partial[$i + $shift]}, { lin => $line, col => $c_pd - $shift - $i, val => $x };
    }
    # shifting the next simple multiplication
    $pos--;
    $shift++;
    $shift_char = '.';
    $line++;
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 2, label => 'DRA02'
               , w1l => $line - 1, w1c => $c_pd + 1 - $multiplicand->chars - $multiplier->chars
               , w2l => $line - 1, w2c => $c_pd);
  push(@action, $action);
  for my $i (0 .. $multiplicand->chars + $multiplier->chars) {
    $final[$i] = { lin => $line, col => $c_pd - $i };
  }
  $result = $self->_adding(\@partial, \@final, $basic_level, $radix);
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $result);
}

method _simple_mult(%param) {
  my $basic_level  = $param{basic_level};
  my $l_md         = $param{l_md}; # coordinates of the multiplicand
  my $c_md         = $param{c_md};
  my $l_mr         = $param{l_mr}; # coordinates of the multiplier (single digit)
  my $c_mr         = $param{c_mr};
  my $l_pd         = $param{l_pd}; # coordinates of the product
  my $c_pd         = $param{c_pd};
  my $multiplicand = $param{multiplicand};
  my $multiplier   = $param{multiplier};
  my $result = '';
  my $radix  = $multiplier->radix;
  my $carry  = '0';
  my $len1   = $multiplicand->chars;
  my Arithmetic::PaperAndPencil::Action $action;
  my Arithmetic::PaperAndPencil::Number $pdt;
  for my $i (0 .. $len1 - 1) {
    my $mul = Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => substr($multiplicand->value, $len1 - $i - 1, 1));
    $pdt = $multiplier * $mul;
    $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'MUL01'                , val3 => $pdt->value
                                                   , r1l => $l_mr, r1c => $c_mr     , r1val => $multiplier->value, val1 => $multiplier->value
                                                   , r2l => $l_md, r2c => $c_md - $i, r2val => $mul->value       , val2 => $mul->value
                                                   );
    push(@action, $action);
    if ($carry ne '0') {
      $pdt += Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $carry);
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 6, label => 'ADD02', val1 => $carry, val2 => $pdt->value);
      push(@action, $action);
    }
    my $unit  = $pdt->unit->value;
    $carry    = $pdt->carry->value;
    my $code = 'WRI02';
    if ($carry eq '0') {
      $code = 'WRI03';
    }
    if ($i < $len1 - 1) {
      $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 5, label => $code, val1 => $unit, val2 => $carry
                   , w1l => $l_pd, w1c => $c_pd - $i, w1val => $unit
                     );
      push(@action, $action);
      $result = $unit . $result;
    }
  }
  $action = Arithmetic::PaperAndPencil::Action->new(level => $basic_level + 3, label => 'WRI00'
               , w1l => $l_pd, w1c => $c_pd + 1 - $len1, w1val => $pdt->value
                 );
  push(@action, $action);
  return Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => $pdt->value . $result);
}


'0 + 0 = (:-|)'; # End of Arithmetic::PaperAndPencil

=head1 NAME

Arithmetic::PaperAndPencil - The great new Arithmetic::PaperAndPencil!

=head1 VERSION

Version 0.01

=cut


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use Arithmetic::PaperAndPencil;

    my $foo = Arithmetic::PaperAndPencil->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=head1 AUTHOR

jforget, C<< <J2N-FORGET at orange.fr> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-arithmetic-paperandpencil at rt.cpan.org>, or through
the web interface at L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Arithmetic-PaperAndPencil>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Arithmetic::PaperAndPencil

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Arithmetic-PaperAndPencil>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Arithmetic-PaperAndPencil>

=item * Search CPAN

L<https://metacpan.org/release/Arithmetic-PaperAndPencil>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2024 by jforget.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

