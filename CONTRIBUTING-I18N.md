-*- encoding: utf-8; indent-tabs-mode: nil -*-

Context
=======

Even if the names of my module  refers to paper and pencil, the module
implements  also  computation  with  chalk and  blackboard.  When  the
teacher  was  giving   an  arithmetic  lesson,  he   would  write  the
computation  on the  board and  simultaneously say  aloud some  ritual
phrases  about the  computation. Same  thing when,  during an  exam or
after an exercise session, a pupil was sent to the blackboard and gave
the solution of the exercises.

Example of such phrase. When starting a division, we would say:

> En 26, combien de fois 6, il y va 4 fois
>
> In 26, how many times 6, it goes there 4 times (my word-to-word translation)

But we would NOT say the more straightforward phrase:

> 26 divisé par 6 égale 4
>
> 26 divided by 6 equals 4 (my word-to-word translation)

This is more  straightforward, but this is _not_  _the_ ritual phrase.
We  were  too  young  to  fully  understand  why  multiplications  and
divisions are computed  the way we were  taught, so we had  to rely on
drill and ritual phrases to learn the basic operations.

Later, when learning more  advanced techniques (gcd, radix conversion,
etc), we  could understand why the  computations were done in  such or
such way. So the phrases were no longer rigid ritual phrases.

I  guess  that 8-year-old  foreign-speaking  pupils  also learn  rigid
ritual formulas  and that 14-year-old foreign-speaking  pupils rely on
understanding  algorithms,  like  I  did. So,  when  providing  a  new
language for  my module,  I need  the ritual phrases  for the  4 basic
operations,  not  a simple  translation.  For  advanced algorithms,  a
simple translation is fine if no ritual phrase exists.

Method
======

Let us suppose that you are a  native German speaker and that you want
to add language `"de"` to my module.

First Step
----------

Clone (or fork) my Github repo.

In  file  `lib/Arithmetic/PaperAndPencil/Label.pm`, in  paragraph
`AUTHOR` of the POD documentation, add a line

> With the help of _your name_ &lt;_your email_&gt; for the "de" language.

In  the `%label`  variable,  add an  entry for  key  `"de"`. Fill  the
associated  value with  a hashtable  containing the  same data  as the
`"fr"` entry. Add  a `todo` marker in each label.  In vi syntax, enter
these two commands:

```
:'b,'es/=> '/=> '!!!/
:'b,'es/=> "/=> "!!!/
```

or these two commands:

```
:'b,'es/=> '/=> 'TODO /
:'b,'es/=> "/=> "TODO /
```

with bookmarks `b` and `e` for the  first and last lines of the `"de"`
entry. If  you prefer, you  can initialise all `"TITnn"`  entries with
the English values instead of the French values.

Iterative Step
--------------

Run a script  which reads a CSV file from  `t/data` or from `xt/data`,
loads  this  CSV  file  into  a  `Arithmetic::PaperAndPencil`  object,
generates the HTML output using the `"de"` language and stores it into
a HTML file. Display  the HTML file in a web browser,  read it and fix
all the labels starting with `"!!!"`  or `"TODO"`. The script file can
be the following, with minor tweaks on the path names:

```
#!/usr/bin/env perl
# -*- encoding: utf-8; indent-tabs-mode: nil -*-

use lib '/path/to/directory/perl-Arithmetic-PaperAndPencil/lib';
use Arithmetic::PaperAndPencil;

my ($file, $level) = @ARGV;
my $lang = 'de';
my $lib  = '/path/to/directory/perl-Arithmetic-PaperAndPencil/xt/data';
my $out  = '/var/tmp';
my $csv  = '';
{
  local $/;
  open my $f, '<', "$lib/$file.csv"
    or die "opening CSV file $!";
  $csv = <$f>;
  close $f
    or die "closing CSV file $!";
}
my $operation = Arithmetic::PaperAndPencil->new;
$operation->from_csv($csv);
$operation->html(lang => $lang, silent => 0, level => $level, pathname => "$out/$file.html");
```

Final Step
----------

As usual, send me a patch or a pull request.

Remarks About Labels
--------------------

The following labels are rigid ritual phrases:

* WRI02, WRI03, WRI04, MUL01, DIV01, DIV02, DIV04, DIV07

The following labels are ritual phrases  with some kind of leeway. The
French version is  shown with "et" (and), but we  often hear a variant
with "plus" instead of "et".

* ADD01, ADD02

The following labels are a special case.

* SUB01, SUB02

In some schools,  including the one which I  attended, subtraction was
taught as a "fill-the-hole" addition. For example, to compute `9 - 6 =
3`, we would say:

> 6 et 3, 9
>
> 6 and 3 equals 9

while in other schools, the pupils would say either:

> 9 moins 6, 3
>
> 9 minus 6 equals 3

or:

> 6 oté de 9, 3
>
> 6 subtracted from 9 equals 3

The following labels are peer-taught ritual phrases. They are not taught by
the (adult) teacher, but by older pupils. "Fastoche" is an alteration of
the French adjective "Facile" (easy).

* MUL02, DIV05, DIV06

The  following  are mere  explanations  for  advanced algorithms,  not
ritual phrases for basic computation methods.

* NXP01, WRI01, WRI05, MUL03, CNV01, CNV02, CNV03, SUB03, SUB04, DIV03, SQR01, SHF01.
