# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use v5.42;
use utf8;
use strict;
use warnings;
use open ':encoding(UTF-8)';
use feature      qw/class/;
use experimental qw/class/;

class Arithmetic::PaperAndPencil::Action 0.02;

field $level :reader :writer :param ;
field $label :reader :param ;
field $val1  :reader :param = '';
field $val2  :reader :param = '';
field $val3  :reader :param = '';
field $r1l   :reader :param = 0;
field $r1c   :reader :param = 0;
field $r1val :reader :param = '';
field $r1str :reader :param = 0;
field $r2l   :reader :param = 0;
field $r2c   :reader :param = 0;
field $r2val :reader :param = '';
field $r2str :reader :param = 0;
field $w1l   :reader :param = 0;
field $w1c   :reader :param = 0;
field $w1val :reader :param = '';
field $w2l   :reader :param = 0;
field $w2c   :reader :param = 0;
field $w2val :reader :param = '';

method from_csv($csv) {
  ($level, $label, $val1, $val2, $val3, $r1l, $r1c, $r1val, $r1str
                                      , $r2l, $r2c, $r2val, $r2str
                                      , $w1l, $w1c, $w1val
                                      , $w2l, $w2c, $w2val)
       = split( /\s*;\s*/, $csv );

}
method csv {
  join(';', $level, $label, $val1, $val2, $val3, $r1l, $r1c, $r1val, $r1str
                                               , $r2l, $r2c, $r2val, $r2str
                                               , $w1l, $w1c, $w1val
                                               , $w2l, $w2c, $w2val)
}

'CQFD'; # End of Arithmetic::PaperAndPencil::Action

=head1 NAME

Arithmetic::PaperAndPencil::Action -- basic action when computing an arithmetic operation

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

This class should  not be used directly.  It is meant to  be a utility
module for C<Arithmetic::PaperAndPencil>.

C<Arithmetic::PaperAndPencil::Action>  is  a   class  storing  various
actions  when computing  an operation:  writing digits  on the  paper,
drawing lines, reading previously written digits, etc.

=head1 SUBROUTINES/METHODS

=head2 from_csv

Loads the attributes of an action with data from a CSV string.

=head2 csv

Produces a CSV string with the attributes of an action.

=head1 AUTHOR

Jean Forget, C<< <J2N-FORGET at orange.fr> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-arithmetic-paperandpencil at rt.cpan.org>, or through the web
interface at
L<https://rt.cpan.org/NoAuth/ReportBug.html?Queue=Arithmetic-PaperAndPencil>.
I will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

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

This software is Copyright (c) 2024, 2026 by Jean Forget.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut

