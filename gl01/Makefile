GUILE_LOAD_PATH := modules

.PHONY: run test

run:
	GUILE_LOAD_PATH=$(GUILE_LOAD_PATH) guile main.scm

test:
	GUILE_AUTO_COMPILE=0 \
	GUILE_LOAD_COMPILED_PATH= \
	GUILE_LOAD_PATH=$(GUILE_LOAD_PATH) \
	guile test.scm
