ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION:-2.6.5}-alpine AS builder

ENV BUILD_PACKAGES build-base git

RUN mkdir /bundle

RUN apk update && \
    apk upgrade && \
    apk add $BUILD_PACKAGES && \
    rm -rf /var/cache/apk/*

COPY djin.gemspec Gemfile Gemfile.lock ./

COPY lib/djin/version.rb lib/djin/version.rb

RUN gem install bundler -v 2.1.4

RUN bundle install

FROM builder AS dev

WORKDIR /usr/src/djin

COPY . .

FROM ruby:2.6.5-alpine

WORKDIR /usr/src/djin

COPY --from=builder /usr/local/bundle/ /usr/local/bundle

RUN gem install bundler -v 2.1.4

ENV DEPENDENCIES git

RUN apk update && \
    apk upgrade && \
    apk add $DEPENDENCIES && \
    rm -rf /var/cache/apk/*

COPY . .

RUN rake install

WORKDIR /usr/src/project

ENTRYPOINT ["/usr/src/verto/docker-entrypoint.sh"]
