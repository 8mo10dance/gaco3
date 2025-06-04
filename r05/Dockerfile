FROM ruby:2.7

WORKDIR /app

RUN gem update --system 3.3.22 && \
    gem install bundler

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

CMD ["bash", "-c", "bundle exec rspec"]
