# -*- encoding: utf-8; indent-tabs-mode: nil -*-

Introduction
============

En 2023, j'ai eu vent de la sortie de la version 5.38 de Perl, version
qui propose un nouveau modèle  objet, Corinna. Pour apprendre Corinna,
il faut pratiquer, donc écrire un logiciel (typiquement un module) qui
utilise Corinna. Or tous les modules dont je m'occupe sont censés être
rétro-compatibles jusqu'à la version 5.8.8 si l'on utilise des chaînes
de caractères ou  jusqu'à une version encore plus ancienne  si l'on ne
fait que  des calculs sans  générer de texte.  Donc je n'avais  pas de
sujet  qui  pourrait  me  donner l'occasion  d'apprendre  Corinna  par
l'expérience.

En parallèle,  d'octobre 2023  à février 2024,  j'ai travaillé  sur un
module Raku `Arithmetic::PaperAndPencil`. Et une fois ce module publié
sur zef, je me suis rendu compte que je pourrais très bien réécrire ce
module en Perl  et que cela me donnerait l'occasion  d'apprendre et de
pratiquer la programmation avec Corinna.

Ce texte ne donne aucune  information sur les fonctionnalités. Si vous
souhaitez avoir des informations sur  comment faire des calcul avec un
papier et un crayon, reportez-vous au
[dépôt Github du module Raku](https://github.com/jforget/raku-Arithmetic-PaperAndPencil)
et à la
[documentation](https://github.com/jforget/raku-Arithmetic-PaperAndPencil/blob/master/doc/Description-fr.md)
qu'il contient. La présente documentation ne s'intéresse
qu'au codage Perl et aux différences avec Raku.

Développement du module
=======================

Environnement technique
-----------------------

Ma machine tourne sous Devuan 4, avec Perl 5.32.1. J'ai donc installé
[perlbrew 0.91](https://metacpan.org/dist/App-perlbrew/view/script/perlbrew)
avec le gestionnaire  de paquets et et j'ai installé  Perl 5.38.2 avec
Perlbrew.

Initialisation
--------------

J'ai initialisé le répertoire de développement du module avec
[Module::Starter](https://metacpan.org/search?q=module%3A%3Astarter)
version 1.77.

Une première surprise. Depuis très longtemps, j'entends dire du mal de
`Module::Build`.   `Module::Build`    était   destiné    à   remplacer
`ExtUtils::MakeMaker`.  Il  présente  des  défauts,  certes,  mais  il
apporte  des  avantages par  rapport  à  `ExtUtils::MakeMaker`. Je  ne
comprends pas pourquoi  de nombreuses personnes de  la communauté Perl
haïssent  `Module::Build`  et  prônent  son  abandon  pour  revenir  à
`ExtUtils::MakeMaker` qui, selon moi  est encore pire. Toujours est-il
que   j'ai   vu   que   `Module::Build`   est   encore   proposé   par
`module-starter`. Il y a aussi `Module::Install`, mais avec la mention
_discouraged_ (« déconseillé »).

Toujours  est-il  que  j'ai  l'impression  que  `ExtUtils::MakeMaker`,
malgré tous ses défauts, a  un avenir plus pérenne que `Module::Build`
et j'ai donc adopté `EUMM` pour mon module.

Lors de  l'initialisation, j'ai  oublié de  demander la  génération du
fichier   `.gitignore`.   Je   l'ai  récupéré   ensuite   en   lançant
`module-starter` sur un module pipeau.  En revanche, j'ai bien précisé
que la version minimale de Perl était la version 5.38.

Organisation de la réécriture
-----------------------------

Lors de l'écriture du module  Raku, j'ai programmé les opérations dans
un ordre  assez surprenant pour  le commun des mortels.  J'ai commencé
par la  multiplication en  jalousie, une  partie de  la multiplication
standard, l'addition,  la fin de  la multiplication standard,  puis la
conversion  d'une base  à l'autre  avec le  procédé multiplicatif  (ou
Horner),  la soustraction,  et ainsi  de suite.  Pour le  module Perl,
comme  j'ai  un modèle  avec  le  module  Raku, je  progresserai  plus
logiquement,  d'abord  l'addition,  puis   la  soustraction,  puis  la
multiplication et ses variantes et ainsi de suite.

Les modules  annexes en Raku ont  été également constitués au  fil des
besoins du module principal. Pour le module Perl, chaque module annexe
est traité d'un seul bloc et testé avec les données de tests recopiées
à partir de la distribution Raku et converties pour la syntaxe Perl.

Premières impressions sur Corinna
---------------------------------

Bien  qu'on ait  sélectionné les  nouveautés  de Perl  5.38 avec  `use
5.38.0;`, il faut ajouter `use  feature qw/class/;` pour bénéficier de
la syntaxe Corinna.

Une mauvaise surprise : je sais bien  que la version 5.38 contient une
version provisoire  et incomplète  de Corinna,  mais je  pensais qu'au
moins il y aurait les attributs `:reader` pour les champs d'objets, ce
qui me dispenserait d'écrire les accesseurs élémentaires. Éh bien non,
les attributs `:reader` ne sont pas  implémentés en 5.38.2 et j'ai été
obligé d'écrire les cinq accesseurs  des cinq champs de `A::PNP::Char`
et  les 19  accesseurs des  19 champs  de `A::PBP::Action`.  Peut-être
devrais-je installer Perl 5.39.xx avec perlbrew ?

Une autre  mauvaise surprise :  lorsque je lance  un fichier  de test,
j'obtiens  quelques messages  `class is  experimental` et  de nombreux
messages `field is experimental` et `method is experimental`. En fait,
j'ai réussi à m'en débarasser en complétant

```
use feature qw/class/;

```

en :

```
use feature      qw/class/;
use experimental qw/class/;

```

Au début, j'ai imité le style de la
[documentation Corinna](https://github.com/Perl-Apollo/Corinna/blob/master/pod/perlclasstut.pod)
et j'ai utilisé la syntaxe de bloc

```
class Arithmetic::PaperAndPencil {
  blablabla
}
```

mais chaque  fois que  je copiais-collais des  pavés de  traitement du
module Raku  vers le  module Perl, il  fallait remettre  la pagination
d'aplomb. Puis en relisant
[la documentation](https://perldoc.perl.org/perlclass)
et pas seulement les exemples, j'ai découvert que
l'on pouvait utiliser la syntaxe d'instruction

```
class Arithmetic::PaperAndPencil;

blablabla;
```

Donc, pour copier-coller entre Raku et  Perl, si la syntaxe du fichier
origine est  la syntaxe de  bloc, adopter la  syntaxe de bloc  pour le
fichier  de destination.  Si  la  syntaxe du  fichier  origine est  la
syntaxe d'instructions,  alors adopter la syntaxe  d'instructions dans
le fichier de destination.

Je n'ai pas  vu s'il existait dans Corinna des  méthodes privées. Dans
l'immédiat, j'ai adopté  la méthode de nommage  traditionelle de Perl,
une méthode est  privée si son nom commence par  un souligné, comme la
méthode `_native_int`  de `A::PNP::Number`. Elle est  publique dans le
cas inverse.

Premières impressions en dehors de Corinna
------------------------------------------

J'ai  appris  Perl  avec  la  version 5.5.2  et,  compte  tenu  de  la
rétro-compatibilité que  doivent assurer  mes modules, compte  tenu du
fait  que j'ai  fait très  peu  de gros  programmes en  dehors de  mes
modules,  j'ai appris  assez peu  de  nouveautés depuis  la 5.12.  Les
dernières  nouveautés  que  j'ai apprises  et  pratiquées  proviennent
essentiellement de la 5.10 :

* la fonction `say`,

* la structure `given` / `when`

* un petit peu de _smart match_ pour accomagner `given` / `when`

* la déclaration de variables lexicales à durée de vie étendue avec `state`,

* les captures nommées dans les expressions rationnelles.

Il y a également `use utf8` qui date, je crois, d'un peu plus tard.

Dommage  que le  _smart match_  ait  été retiré  à cause  de cas  très
particuliers, dommage que le `given` / `when` l'ait accompagné dans sa
disparition.

Lorsque j'ai  copié-collé des méthodes  ou des fonctions de  Raku vers
Perl, j'ai essayé de recopier les signatures telles quelles, comme

```
sub filling-spaces(Int $l, Int $c) {
```

J'ai changé  le tiret en souligné  sans me poser de  question. Pour la
signature, j'ai  essayé de l'utiliser  telle quelle. Perl  5.38 n'aime
pas les déclarations de type `Int` ou autres. En revanche, il admet la
déclaration des paramètres de fonction et j'ai pu ainsi écrire :

```
sub filling_spaces($l, $c) {
```

au lieu de

```
sub filling_spaces {
  my ($l, $c) = @_;
```

Cela représente un gain de temps et un gain de lisibilité appréciables.

Une autre nouveauté que j'ai bien aimée, c'est le fait que l'on puisse
définir  une fonction  à l'intérieur  d'une autre  fonction (ou  d'une
méthode). Voir les  fonctions `check_l_min`, `l2p_lin`, `check_c_min`,
`l2p_col` et `filling_spaces` dans la méthode `html`.

En revanche, il y a une nouveauté  qui manque. Nous sommes en 2024, la
quasi-totalité  des logiciels  de  développement  (éditeurs, bases  de
données, compilateurs) traitent convenablement  les chaînes Unicode en
UTF-8, et  pourtant, par  défaut, l'interpréteur `perl`  considère que
les  fichiers sources  et les  fichiers  de données  sont toujours  en
ISO-8859-1 ou  similaire. Certes, il  y a la  rétro-compatibilité avec
les programmes  écrits au siècle  dernier. Mais dès  qu'un programmeur
écrit `use  5.38.0` ou même `use  5.10`, on sait qu'il  n'est plus lié
par une rétro-compatibilité s'étendant  jusqu'à des périodes précédant
l'arrivée  d'Unicode,  donc   l'interpréteur  `perl`  devrait  adopter
Unicode par défaut  dans ce cas. Éh bien non,  je suis toujours obligé
d'ajouter

```
use utf8;
use open ':encoding(UTF-8)';
```

Problèmes recontrés
-------------------

### Premier problème pour `A:PNP::Char`

Le premier  problème s'est manifesté  lors de la génération  du source
HTML à partir d'une liste d'actions.

À un  moment, il faut  insérer une ou  plusieurs colonnes au  début de
chaque ligne de  l'opération et remplir ces colonnes  avec des espaces
(en fait des instances de `A::PNP::Char`). Le module calcule le nombre
de  colonnes à  insérer  `$delta_c` (ou,  en  Raku, `$delta-c`),  puis
lance :

```
      for @sheet <-> $line {
        prepend $line, space-char() xx $delta-c;
      }
```

La fonction `space-char`  est la fonction qui fournit  une instance de
`A::PNP::Char` contenant  un espace. Ma  première tentative en  Perl a
été :

```
      for my $line (@sheet) {
        unshift @$line, (Arithmetic::PaperAndPencil::Char->space_char) x $delta_c;
      }
```

Cela  ne fonctionnait  pas.  Le test  `01-action.t`, transcription  de
`06-html.rakutest`, écrivait  `133` là où  il aurait dû  écrire `123`.
Après  un  peu  de  débugage,  j'ai  compris  que  sur  chaque  ligne,
l'instruction  `unshift`  insérait  deux  fois  la  même  instance  de
`space_char` au début  de la ligne. En revanche, en  Raku, le problème
ne se  manifestait pas. Soit  `space-char() xx $delta-c`  appelle deux
fois la fonction `space-char` pour créer deux instances différentes de
`A::PNP::Char`,  soit  l'instruction   `prepend`  effectue  une  copie
profonde (_deep copy_). Toujours est-il  que, pour corriger la version
Perl, j'ai dû écrire :

```
      for my $line (@sheet) {
        for (1 .. $delta_c) {
          unshift @$line, Arithmetic::PaperAndPencil::Char->space_char;
        }
      }
```

### Deuxième problème pour `A:PNP::Char`

Le  programme  de  test  `01-action.t` comporte  deux  générations  de
sources HTML. J'ai commencé par  tester seulement la première, jusqu'à
ce  que cela  fonctionne.  Ensuite, lorsque  j'ai  ajouté la  deuxième
génération,  cela  ne  fonctionnait   plus.  Avec  le  débugage,  j'ai
identifié que cela  se produisait au moins dans  `check_l_min` et dans
`l2p_lin`. Peut-être  y a-t-il  un problème  analogue avec  les autres
fonctions intérieures `check_c_min`, `l2p_col` et `filling_spaces`, je
n'ai pas vérifié. J'explique uniquement avec `l2p_lin`, dans un but de
concision. Voici cette fonction :

```
  sub l2p_lin($logl) {
    my $result = $logl - $l_min;
    return $result;
  }
```

Cette fonction  utilise un paramètre  d'appel `$logl` et  une variable
globale  `$l_min`  (en  fait,  une variable  lexicale  de  la  méthode
englobante). Au fur et à mesure  de la génération d'un source HTML, la
variable `$l_min` prend les valeurs 0, -1,  -3 et -4 (oui, on saute -2
parce qu'il faut insérer deux  colonnes simultanément). Or, lors de la
deuxième génération, lorsque je demande l'affichage de `$l_min` depuis
l'intérieur de `l2p_lin`, le programme  affiche -4 dès le début, alors
que si je  demande l'affichage depuis la méthode  `html` à l'extérieur
de `l2p_lin`, j'obtiens bien 0.

Voici mon hypothèse pour l'explication. Lors de la première génération
de HTML, la fonction utilise la variable `$l_min` à sa bonne valeur, 0
puis -1  puis -3 et enfin  -4. Lorsque la méthode  `html` s'achève, la
fonction  continue  à  exister  avec le  mécanisme  des  clôtures.  La
variable `$l_min`,  référencée dans cette clôture,  continue à exister
avec la valeur -4. Puis la méthode `html` est lancée une deuxième fois
pour  le test  avec  CSS. Cela  définit une  nouvelle  instance de  la
variable lexicale `$l_min`,  initialisée à 0. En  revanche, en passant
dans la définition

```
  sub l2p_lin($logl) {
    my $result = $logl - $l_min;
    return $result;
  }
```

cela ne redéfinit  pas la fonction `l2p_lin`, qui existe  déjà dans la
clôture. Donc les appels ultérieurs  à `l2p_lin` utilisent la clôture,
avec `$l_min` à -4. La solution a été très simple, ajouter un `my`

```
  my sub l2p_lin($logl) {
    my $result = $logl - $l_min;
    return $result;
  }
```

J'ai écrit  plus haut  que je  n'avais pas vérifié  si le  problème se
posait  aussi pour  `check_c_min`, `l2p_col`  et `filling_spaces`.  De
façon involontaire, j'ai  quand même vérifié. En effet,  dans la liste
des fonctions intérieures,  il y a aussi `draw_h` et,  dans un premier
temps, je  ne lui  ai pas ajouté  de déclaration `my`.  Et le  test de
`01-action.t`  a échoué  à  cause d'un  soulignement  qui n'était  pas
effectué. Et  lorsque j'ai  collé la déclaration  `my` à  `draw_h`, le
test a réussi.

### Problèmes rencontrés pour `A::PNP::Number`

À  quelques endroits  du module,  j'ai besoin  de convertir  un nombre
`A::PNP::Number` d'un seul chiffre en  un entier natif. Pour ce faire,
en Raku, j'utilise le tableau à 36 éléments

```
@digits = ( '0' .. '9', 'A' .. 'Z');
```

et je recherche la position du chiffre traité `$.unit.value` dans ce tableau, avec

```
  my Int $units = @digits.first: * eq $.unit.value, :k;
```

Il existe un équivalent en Perl, à condition de charger le module
[`List::MoreUtils`](https://metacpan.org/pod/List::MoreUtils)
et d'utiliser la fonction
[`first_index`](https://metacpan.org/pod/List::MoreUtils#firstidx-BLOCK-LIST)
ou `firstidx`. J'ai donc codé :

```
  use List::MoreUtils qw/first_index/;
  ...
  my $units = first_index { * eq $.unit.value } @digits;

```

mais cela  n'a jamais fonctionné,  il y  avait une erreur  de syntaxe.
Pour contourner le  problème, j'ai créé un  hachage `%digit_value` qui
donne le même résultat. C'est  aussi bien, mais j'aimerais bien savoir
pourquoi le module `List::MoreUtils` ne passe pas.

Ou alors,  la solution était  la même que  pour le second  problème de
`Number.pm`.  Voici  ce second  problème.  J'ai  besoin d'émettre  des
messages d'erreur avec `croak` et  j'ai besoin de calculer des parties
entières  avec `floor`.  J'ai donc  appelé les  modules correspondants
avec :

```
use Carp;
use POSIX qw/floor/;

class Arithmetic::PaperAndPencil::Number 0.01;
```

Cela m'a donné des messages d'erreur tels que

```
Undefined subroutine &Arithmetic::PaperAndPencil::Number::floor called at lib/Arithmetic/PaperAndPencil/Number.pm line 179.
```

Cela allait mieux avec `Carp::croak` et `POSIX::floor`, mais ce n'est pas idéal. Puis
j'ai codé :

```
class Arithmetic::PaperAndPencil::Number 0.01;

use Carp;
use POSIX qw/floor/;
```

et là, cela fonctionnait mieux, on pouvait utiliser `croak` et `floor`
sans leur ajouter le nom de paquetage.

Pour  en  revenir  à  `List::MoreUtils`,  le  message  d'erreur  était
différent et  mentionnait clairement qu'il s'agissait  d'une erreur de
syntaxe. Mais  peut-être que Perl affichait  ce message à cause  de la
syntaxe inhabituelle des différentes fonctions de `List::MoreUtils` et
que si j'avais placé le  `use List::MoreUtils` après la ligne `class`,
cela  aurait fonctionné.  Tant pis,  je conserve  la solution  avec le
hachage `%digit_value`.

Un autre  problème, déjà connu depuis  belle lurette, est que  l'on ne
peut pas utiliser de variables dans un opérateur `tr`. D'où le recours
à un `eval`

```
  my $before = substr($digits, 0, $radix);
  my $after  = reverse($before);
  $_ = '0' x ($len - length($s)) . $s;
  eval "tr/$before/$after/";
```

Une  bonne  nouvelle,  `overload`  continue  à  fonctionner,  même  en
utilisant Corinna.  Je pourrais  effectuer des  additions avec  `+` au
lieu de `☈+` et des soustractions avec  `-` au lieu de `☈-`. Bon, pour
la multiplication,  je suis obligé  de revenir à cette  étoile stupide
`*` au lieu  du véritable signe de multiplication `×`  (ou la variante
de mon module Raku `☈×`).

Et pour mémoire, à plusieurs reprises j'ai eu recours à un
[opérateur secret de Perl](https://metacpan.org/dist/perlsecret/view/lib/perlsecret.pod),
notamment
l'[opérateur Vénus](https://metacpan.org/dist/perlsecret/view/lib/perlsecret.pod#Venus)
pour tester les résultats booléens sous la forme `0` ou `1`
et l'[opérateur landau](https://metacpan.org/dist/perlsecret/view/lib/perlsecret.pod#Baby-cart)
pour insérer des appels de méthode dans des chaînes de caractères.

### Problèmes pour la méthode `addition`

Je n'ai  pas vraiment eu  de problèmes, si ce  n'est que c'est  un peu
gonflant  de changer  `if condition  {` en  `if (condition)  {` ou  de
changer

```
my Arithmetic::PaperAndPencil::Number $x .= new(radix => $radix, value => '10');
```

en

```
my $x =  Arithmetic::PaperAndPencil::Number->new(radix => $radix, value => '10');
```

J'ai donc adapté le fichier  de configuration d'Emacs pour automatiser
ces modifications. J'en ai profité pour ajouter d'autres modifications
répétitives. C'est quand même  la version interactive du remplacement,
commençant par  `query-`, car  certaines modifications  sont inutiles,
voire à éviter, comme par exemple  remplacer un point par un `->` dans
un nom  de fichier `toto.csv`  sous prétexte  que cela ressemble  à un
appel de méthode.  Je n'ai pas tout codé,  car certaines modifications
sont   plus    délicates,   comme   remplacer    `%label<TIT01>`   par
`$label{TIT01}` ou changer

```
  for @numbers.kv -> $i, $n {
```

en

```
  for my $i (0 .. $#numbers) {
    my $n = $numbers[$i];
```

Un problème qui, pour l'instant, ne m'a pas trop gêné, mais qui risque
d'être épineux à l'avenir, c'est l'appel des fonctions ou des méthodes
avec  des  paramètres  définis  par mots-clés.  Il  faudra  revenir  à
l'ancienne  méthode  où  l'on  récupérait la  variable  `@_`  pour  la
recopier dans un hachage.

### Problèmes pour la méthode `subtraction`

Pas  de problème  en fait.  En revanche,  j'ai (re)découvert  que l'on
pouvait attribuer un type à une déclaration `my`, si le type est connu
en tant que classe d'objet. Ainsi,

```
  my Arithmetic::PaperAndPencil::Action $action;
```

est valide, mais

```
  my Int $i;
```

ne l'est pas. Est-ce que cela permet de raccourcir les appels de `new`
pour faire  aussi bref qu'en  Raku ? Je ne le  pense pas. Je  n'ai pas
essayé.
