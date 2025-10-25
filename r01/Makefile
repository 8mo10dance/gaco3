export RAILS_ENV ?= test
export AWS_ACCESS_KEY_ID ?= dummy
export AWS_SECRET_ACCESS_KEY ?= dummy

.PHONY: rspec

rspec: install-gems db-migrate
	bundle exec rspec

install-gems:
	bundle install --jobs 4 --retry 3

db-migrate:
	bundle exec rake db:migrate
