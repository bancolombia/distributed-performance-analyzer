FROM elixir:1.14.4-alpine AS builder
WORKDIR /app
ENV MIX_ENV=prod
RUN apk add build-base git \
    && mix local.hex --force \
    && mix local.rebar --force
COPY mix.exs mix.lock .
RUN mix deps.get \
    && mix deps.compile
COPY . .
RUN mix escript.build

FROM elixir:1.14.4-alpine
WORKDIR /app
COPY --from=builder /app/distributed_performance_analyzer .
COPY config /app/config
VOLUME /app/config/
ENTRYPOINT exec /app/distributed_performance_analyzer