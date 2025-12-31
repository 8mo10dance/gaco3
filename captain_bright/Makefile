.PHONY: build setup

build: Dockerfile.dev
	docker compose build

setup: build
	docker compose run --rm web bundle exec rails db:migrate
