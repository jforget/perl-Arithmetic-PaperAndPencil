-*- encoding: utf-8; indent-tabs-mode: nil -*-

This directory contains data files used when testing `Arithmetic::PaperAndPencil`.

CSV Files
---------

No comments.

HTML Files
----------

Except for `21-ref4.html`,  all HTML files are  partial files, lacking
the `< html>`  and `< body>` tags.  Yet, they can be  displayed by any
Internet browser. So they have two purposes:

* running tests,

* showcasing the module.

L<sup>A</sup>T<sub>E</sub>X Files
-----------

Unlike HTML files, L<sup>A</sup>T<sub>E</sub>X  files must be complete
and syntactically correct  in order to be compiled  and rendered. File
`21-ref2.tex` is  syntactically incorrect.  This is  deliberate. Other
files are syntactically correct.

There are  only 3 correct L<sup>A</sup>T<sub>E</sub>X  files, which is
insufficient  to showcase  the module.  They  are used  only for  test
purposes.

While  the  `latex`  method  is   built,  there  are  test  errors  in
`t/01-action.t`   and  `xt/21-file-output.t`.   When  the   method  is
complete, the errors should disappear.
