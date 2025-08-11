(use-modules (guix packages)
	     (guix build-system guile)
	     (gnu packages guile))

(package
 (name "gl01")
 (version "0.1")
 (source #f)
 (build-system guile-build-system)
 (inputs (list guile-3.0)))
