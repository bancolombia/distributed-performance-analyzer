FROM elixir:1.15-alpine AS base
ENV APP_NAME=distributed_performance_analyzer
ENV MIX_ENV=prod
WORKDIR /app
RUN apk update --no-cache && \
    apk upgrade --available --purge --no-cache && \
    rm -rf /var/cache/apk/*

FROM base AS builder
RUN apk add build-base git
RUN mix do local.hex --force, local.rebar --force
COPY mix.exs mix.lock ./
RUN mix do deps.get --only $MIX_ENV, deps.compile
COPY . ./
RUN mix release

FROM base
COPY --from=builder /app/_build/$MIX_ENV/rel/$APP_NAME ./
COPY config config
VOLUME config
ENV MIX_ENV=performance
ENTRYPOINT bin/$APP_NAME start