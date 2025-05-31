(define (firsts xs)
  (map car xs))

(define (insertR new old xs)
  (cond ((null? xs)
	 '())
	((eq? old (car xs))
	 (cons (car xs)
	       (cons new (cdr xs))))
	(else
	 (cons (car xs)
	       (insertR new old (cdr xs))))))
