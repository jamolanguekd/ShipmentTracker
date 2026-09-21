FROM ruby:3.1.6-alpine

RUN apk add --no-cache \
    build-base \
    postgresql-dev \
    tzdata \
    git

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

RUN mkdir -p tmp/pids

EXPOSE 3000

CMD ["bin/rails", "server", "-b", "0.0.0.0"]
