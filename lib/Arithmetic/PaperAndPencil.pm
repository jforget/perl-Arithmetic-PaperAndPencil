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
use Arithmetic::PaperAndPencil::Number;

class Arithmetic::PaperAndPencil 0.01;

field @action;

method from_csv {
  my ($csv) = @_;
  @action = ();
  for my $line (split("\n", $csv)) {
    my $action = Arithmetic::PaperAndPencil::Action->new;
    $action->from_csv($line);
    push @action, $action;
  }
}
method csv {
  join "\n", map { $_->csv } @action;
}
method html($lang, $silent, $level, $css) {
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
      $sheet[$l1][0] //=  Arithmetic::PaperAndPencil::Char->space_char;
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
        $sheet[l2p_lin($l)][l2p_col($action->w1c) + 1] =  Arithmetic::PaperAndPencil::Char->pipe_char;
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

