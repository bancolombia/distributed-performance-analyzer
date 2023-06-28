FROM elixir:1.15.0-alpine AS base
ENV APP_NAME=distributed_performance_analyzer
ENV MIX_ENV=prod
WORKDIR /app
RUN apk update --no-cache && \
    apk upgrade --available --purge --no-cache && \
    rm -rf /var/cache/apk/*

FROM base AS builder
RUN apk add build-base git
RUN mix local.hex --force && \
    mix local.rebar --force
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile
COPY . ./
RUN mix escript.build

FROM base
COPY --from=builder /app/$APP_NAME ./
COPY config config
VOLUME config
ENTRYPOINT exec ./$APP_NAME