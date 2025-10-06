ARG RUBY_VERSION

FROM ruby:$RUBY_VERSION

WORKDIR /ruby

# bundle install 時の ffi-1.17.1-x86_64-linux-musl のエラーのため
RUN gem update --system 3.3.22 && \
    gem install bundler

COPY Gemfile Gemfile.lock .

RUN bundle install

CMD ["/usr/bin/bash"]
