FROM elixir:1.13.3-alpine
RUN apk add build-base
WORKDIR /app
COPY . /app
RUN mix local.hex --force \
    && mix local.rebar --force \
    && mix deps.get \
    && mix deps.compile \
    && MIX_ENV=prod mix escript.build

FROM elixir:1.13.3-alpine
WORKDIR /app
RUN apk update && apk upgrade && apk add bash
COPY --from=0 /app/perf_analyzer /app
COPY datasets /app/datasets/
COPY config /app/config
VOLUME /app/config/
ENTRYPOINT exec /app/perf_analyzer