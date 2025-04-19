(use-modules (srfi srfi-64))
(use-modules (deep-collection))

(test-begin "deep-collection tests")

(test-equal "deep double of '(1 2 (3 4)) should be '(2 4 (6 8))"
  '(2 4 (6 8))
  (deep-map (lambda (x) (* x 2)) '(1 2 (3 4))))

(test-end "deep-collection tests")
