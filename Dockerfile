FROM ruby:4.0.1-alpine

RUN apk add --no-cache \
  build-base \
  postgresql-dev \
  postgresql-client \
  git \
  bash \
  tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3

COPY . .

EXPOSE 3000

CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "-p", "3000"]