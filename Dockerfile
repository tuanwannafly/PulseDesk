FROM ruby:3.2-slim

RUN apt-get update -qq && apt-get install -yq --no-install-recommends \
      build-essential libpq-dev postgresql-client nodejs npm \
    && npm install -g yarn \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle config set --local without 'development test' && bundle install

COPY . .

RUN bin/rails tailwindcss:build || true

ENV RAILS_SERVE_STATIC_FILES=true \
    RAILS_LOG_TO_STDOUT=true

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]