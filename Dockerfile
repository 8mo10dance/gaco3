ARG RUBY_VERSION

FROM ruby:$RUBY_VERSION

WORKDIR /ruby

COPY Gemfile Gemfile.lock .

RUN bundle install

CMD ["/usr/bin/bash"]
