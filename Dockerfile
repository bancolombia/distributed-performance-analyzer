FROM elixir:1.15-alpine AS base
ENV APP_NAME=distributed_performance_analyzer
WORKDIR /app
RUN apk update --no-cache && \
    apk upgrade --available --purge --no-cache && \
    rm -rf /var/cache/apk/*

FROM base AS builder
ENV MIX_ENV=prod
RUN apk add build-base git
RUN mix do local.hex --force, local.rebar --force
COPY mix.exs mix.lock ./
RUN mix do deps.get, deps.compile
COPY . ./
RUN mix release

FROM base
ENV MIX_ENV=performance
COPY --from=builder /app/_build/prod ./
COPY config config
VOLUME config
ENTRYPOINT rel/$APP_NAME/bin/$APP_NAME start