GUILE_LOAD_PATH := modules
GUIX := guix shell -m manifest.scm --

.PHONY: run test

run:
	$(GUIX) env \
		GUILE_LOAD_PATH=$(GUILE_LOAD_PATH) \
		guile main.scm

test:
	$(GUIX) env \
		GUILE_AUTO_COMPILE=0 \
		GUILE_LOAD_COMPILED_PATH= \
		GUILE_LOAD_PATH=$(GUILE_LOAD_PATH) \
		guile test.scm
