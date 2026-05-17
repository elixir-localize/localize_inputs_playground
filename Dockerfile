# Multi-stage build for deploying Localize.Inputs.Playground
# (Localize.Inputs.Playground.Visualizer) on Fly.io.
#
# No Node.js, no asset pipeline — the visualizer's CSS and JS
# are compiled into BEAM modules at build time inside the
# `localize_inputs_*` libraries.

# ---- build stage ----
ARG ELIXIR_VERSION=1.19.5
ARG OTP_VERSION=28.2
ARG DEBIAN_VERSION=bookworm-20260202-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

RUN apt-get update -y && \
    apt-get install -y build-essential git && \
    apt-get clean && rm -f /var/lib/apt/lists/*_*

ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

WORKDIR /app

# Cache deps layer — only re-fetched when mix.exs/mix.lock change.
COPY mix.exs mix.lock ./

# Fetch and compile deps.
RUN mix deps.get --only $MIX_ENV
RUN mix deps.compile

# Copy the rest of the source and compile.
COPY config config
COPY lib lib
# priv/gettext holds the .po catalogs that the MoneyInputPlayground.Gettext
# backend compiles in. Without this COPY the catalog is empty in the
# container and Gettext.known_locales returns [], causing every
# `Localize.Plug.PutLocale` lookup to fall back to a "no matching
# Gettext locale" warning and skip put_locale entirely.
COPY priv priv
RUN mix compile

# Build the release.
RUN mix release

# ---- runtime stage ----
FROM ${RUNNER_IMAGE}

RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
       libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen \
    && locale-gen

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/localize_inputs_playground ./

CMD ["/app/bin/localize_inputs_playground", "start"]
