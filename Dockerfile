FROM elixir:1.14.5-alpine AS builder
WORKDIR /app
RUN apk add build-base git \
    && mix local.hex --force \
    && mix local.rebar --force
COPY mix.exs mix.lock ./
RUN mix deps.get \
    && mix deps.compile
COPY . .
RUN MIX_ENV=prod mix escript.build

FROM elixir:1.14.5-alpine
WORKDIR /app
COPY --from=builder /app/distributed_performance_analyzer .
COPY config /app/config
VOLUME /app/config/
ENTRYPOINT exec /app/distributed_performance_analyzer