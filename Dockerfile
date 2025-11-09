
FROM ruby:3.3-slim AS builder

ENV BUNDLE_PATH /usr/local/bundle
WORKDIR /app

RUN apt-get update -qq && apt-get install -y --no-install-recommends build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./ 

RUN bundle config set deployment 'true' \
 && bundle config set without 'development test' \
 && bundle install --jobs 4 --retry 3


FROM ruby:3.3-slim AS production

ENV APP_HOME=/app
ENV RACK_ENV=production
ENV PORT=3000


ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH /usr/local/bundle
ENV PATH /usr/local/bundle/bin:$PATH

WORKDIR $APP_HOME

RUN apt-get update -qq && apt-get install -y --no-install-recommends netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder $BUNDLE_PATH $BUNDLE_PATH

COPY Gemfile Gemfile.lock config.ru app.rb ./

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-b", "tcp://0.0.0.0:3000", "config.ru"]
