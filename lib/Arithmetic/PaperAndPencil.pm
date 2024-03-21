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
    $action = Arithmetic::PaperAndPencil::Action->new(level => 5, label => 'SUB03', val1 => $radix, val2 => $low->value, val3 => $complement->value
                                               , w1l => 0, w1c => $leng, w1val => $high->value
                                               , w2l => 1, w2c => $leng, w2val => $complement->value);
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

