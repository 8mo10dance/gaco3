(define-module (rspec-like-dsl)
  #:export (describe it))

(use-modules (srfi srfi-64))

(define-syntax describe
  (syntax-rules ()
    ((_ name body ...)
     (begin
       (test-begin name)
       body ...
       (test-end name)))))

(define-syntax it
  (syntax-rules ()
    ((_ name actual expected)
     (test-equal name expected actual))))
