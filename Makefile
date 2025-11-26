RUBY_VERSION      ?= 3.3.10
APP_NAME          ?= myapp
RAILS_NEW_OPTIONS ?= --skip-javascript --skip-test

IMAGE_NAME        ?= rails-new:$(RUBY_VERSION)
WORKDIR           := $(CURDIR)

.PHONY: build new

new: build
	@echo "To run: rails new $(APP_NAME) $(RAILS_NEW_OPTIONS)"
	docker run --rm \
		-v "$(WORKDIR)":/ruby \
		-w /ruby \
		$(IMAGE_NAME) \
		rails new /ruby/$(APP_NAME) $(RAILS_NEW_OPTIONS)

build: Dockerfile
	@echo "Ruby Version: $(RUBY_VERSION)"
	docker build \
		--build-arg RUBY_VERSION=$(RUBY_VERSION) \
		-t $(IMAGE_NAME) \
		.
