export RAILS_ENV ?= test
export AWS_ACCESS_KEY_ID ?= dummy
export AWS_SECRET_ACCESS_KEY ?= dummy

.PHONY: rspec clean

rspec: install-gems db-migrate
	bundle exec rspec

clean:
	rm -rf vendor/bundle

install-gems: setup
	bundle install --jobs 4 --retry 3

setup:
	bundle config set path 'vendor/bundle'
	bundle config set without 'development'
	bundle config set deployment 'false'

db-migrate:
	bundle exec rake db:migrate
