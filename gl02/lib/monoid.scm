(define-module (monoid)
  #:export (accumulate))

(define (accumulate T n)
  (cond ((= n 0) (lambda (x) x))
	(else
	 (combine T
		  (accumulate T (- n 1))))))

(define (combine T1 T2)
  (lambda (x)
    (T2 (T1 x))))
