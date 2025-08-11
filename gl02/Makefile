GUILE_LOAD_PATH := lib
GUIX := guix shell -m manifest.scm --

.PHONY: run

run:
	$(GUIX) env \
		GUILE_LOAD_PATH=$(GUILE_LOAD_PATH) \
		guile main.scm
