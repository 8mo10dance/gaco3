(define-module (deep-collection)
  #:export (deep-map deep-any? deep-all?))

(define (deep-fold combine x-base xs-base xs)
  (define (x-apply x)
    (cond ((list? x)
           (iter x))
          (else
           (xs-base x))))
  (define (x-combine x y)
    (combine (x-apply x) y))
  (define (iter xs)
    (cond ((null? xs)
           x-base)
          (else
           (x-combine (car xs)
                      (iter (cdr xs))))))
  (iter xs))

(define (deep-map f xs)
  (deep-fold cons '() f xs))

(define (deep-any? f xs)
  (deep-fold (lambda (x y) (or x y)) #f f xs))

(define (deep-all? f xs)
  (deep-fold (lambda (x y) (and x y)) #t f xs))
