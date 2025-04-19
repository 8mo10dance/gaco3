(use-modules (deep-collection))

(display (deep-map (lambda (x) (* x 2))
                   '((5 3) ((12 1) 34) 3 1)))
(newline)
