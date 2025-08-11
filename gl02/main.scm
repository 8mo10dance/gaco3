(define (pow base n)
  (let* ((T (lambda (x) (* base x)))
	 (Tn (accumulate T n)))
    (Tn 1)))

(define (fib n)
  (let* ((T (lambda (v)
	      (mtx-mul-by-vec '((1 1)
				(1 0)) v)))
	 (Tn (accumulate T n)))
    (car (Tn '(1 0)))))

(define (mtx-mul-by-vec A v)
  (map (lambda (row)
	 (apply + (map * row v)))
       A))

(define (accumulate T n)
  (cond ((= n 0) (lambda (x) x))
	(else
	 (combine T
		  (accumulate T (- n 1))))))

(define (combine T1 T2)
  (lambda (x)
    (T2 (T1 x))))

(display (pow 2 10))
(newline)

(display (fib 10))
(newline)
