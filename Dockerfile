FROM elixir:1.14.4-alpine
RUN apk add git build-base
WORKDIR /app
COPY . /app
RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get \
    && mix deps.compile \
    && MIX_ENV=prod mix escript.build

FROM alpine:3.17.3
WORKDIR /app
RUN apk update && apk upgrade && apk add bash
COPY --from=0 /app/perf_analyzer /app
COPY config /app/config
VOLUME /app/config/
ENTRYPOINT exec /app/perf_analyzer