-*- encoding: utf-8; indent-tabs-mode: nil -*-

Ce répertoire contient  des fichiers de données pour  tester le module
`Arithmetic::PaperAndPencil`.

Fichiers CSV
------------

Rien à signaler.

Fichiers HTML
-------------

À  l'exception   de  `21-ref4.html`,  tous  les   fichiers  HTML  sont
incomplets, privés notamment des balises  `< html>` et `< body>`. Cela
dit, cela  n'empêche pas de les  afficher dans un navigateur  web. Ces
fichiers ont donc deux rôles :

* faire passer les tests,

* donner un aperçu du module.

Fichiers L<sup>A</sup>T<sub>E</sub>X
-----------

À l'inverse des fichiers HTML, les fichiers
L<sup>A</sup>T<sub>E</sub>X doivent avoir une syntaxe correcte pour
pouvoir être compilés et affichés. Le fichier `21-ref2.tex` est
incorrect, c'est normal. Pour les autres, la syntaxe est correcte.

Il n'y a  que 3 fichiers L<sup>A</sup>T<sub>E</sub>X  corrects, ce qui
est insuffisant pour  donner un aperçu suffisant du  module. Leur seul
rôle consiste à faire passer les tests.

Le  temps de  construire la  méthode `latex`,  il pourra  y avoir  des
erreurs  dans `t/01-action.t`  et `xt/21-file-output.t`.  Une fois  la
méthode achevée, les erreurs devraient disparaître.
