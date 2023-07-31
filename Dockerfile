FROM elixir:1.15.4-alpine AS base
ENV APP_NAME=distributed_performance_analyzer \
    UID=10101 \
    USER=dpa
ENV WORKDIR=/home/$USER
RUN apk update --no-cache && \
    apk upgrade --available --purge --no-cache && \
    rm -rf /var/cache/apk/*
RUN mkdir -p $WORKDIR && \
  chmod -R 0755 $WORKDIR
RUN addgroup -S -g $UID $USER && \
    adduser -S -D -s /sbin/nologin -h $WORKDIR -G $USER -u $UID $USER
WORKDIR $WORKDIR

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
COPY --from=builder --chown=$USER:$USER $WORKDIR/_build/prod ./
COPY --chown=$USER:$USER config config
VOLUME config
USER $USER
ENTRYPOINT rel/$APP_NAME/bin/$APP_NAME start