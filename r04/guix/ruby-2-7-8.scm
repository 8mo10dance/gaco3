(define-module (ruby-2-7-8)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system ruby)
  #:use-module (gnu packages ruby)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages tls))

(define-public ruby-2.7.8
  (package
    (inherit ruby-2.7)
    (name "ruby-2.7.8")
    (version "2.7.8")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://cache.ruby-lang.org/pub/ruby/2.7/ruby-"
                                  version ".tar.gz"))
              (sha256
               (base32 "182vni66djmiqagwzfsd0za7x9k3zag43b88c590aalgphybdnn2"))))))
