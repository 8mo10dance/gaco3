(define-module (mylib hello)
  #:export (greet))

(define (greet name)
  (string-append "こんにちは, " name "！"))
