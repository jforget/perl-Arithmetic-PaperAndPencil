; -*- encoding: utf-8; indent-tabs-mode: nil -*-
(progn
(defun md-arrow         () (interactive) (insert "→"))  ; U+2192 rightwards arrow
(defun md-less-equal    () (interactive) (insert "≤"))  ; U+2264 less-than or equal to
(defun md-greater-equal () (interactive) (insert "≥"))  ; U+2265 greater-than or equal to
(defun md-backquotes    () (interactive) (insert "``")   (forward-char -1))
(defun md-guillemets    () (interactive) (insert "«  »") (forward-char -2))
(defun md-programme     () (interactive) (insert "\n```\n\n```\n") (forward-line -2))
(defun raku-add         () (interactive) (insert "☈+"))  ; U+2608 thunderstorm
(defun raku-times       () (interactive) (insert "☈×"))  ; U+2608 thunderstorm, U+00D7 multiplication sign
(defun raku-divide      () (interactive) (insert "☈÷"))  ; U+2608 thunderstorm, U+00F7 division sign
  (define-key global-map "\C-c-"      'md-arrow)
  (define-key global-map "\C-c<"      'md-less-equal)
  (define-key global-map "\C-c>"      'md-greater-equal)
  (define-key global-map "\C-cè"      'md-backquotes)
  (define-key global-map "\C-c\C-c<"  'md-guillemets)
  (define-key global-map "\C-cp"      'md-programme)
  (define-key global-map "\C-c+"      'raku-add)
  (define-key global-map "\C-cx"      'raku-times)
  (define-key global-map "\C-c:"      'raku-divide)
)
