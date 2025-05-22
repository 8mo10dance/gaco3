FROM ruby:2.7.8

WORKDIR /rails

# bundle install 時の ffi-1.17.1-x86_64-linux-musl のエラーのため
RUN gem update --system 3.3.22

EXPOSE 3000
CMD bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0"
