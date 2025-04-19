(use-modules (rspec-like-dsl))
(use-modules (deep-collection))

(describe "deep-collection tests"
          (it "deep double of '(1 2 (3 4)) should be '(2 4 (6 8))"
              (deep-map (lambda (x) (* x 2)) '(1 2 (3 4)))
              '(2 4 (6 8))))
