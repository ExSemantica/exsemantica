ARG VER_ELIXIR
ARG VER_ERLANG
FROM hexpm/elixir:${VER_ELIXIR}-erlang-${VER_ERLANG}-ubuntu-focal-20210325

ENV DEBIAN_FRONTEND="noninteractive"
RUN apt update -yy && \
    apt upgrade -yy && \
    apt install -yy curl && \
    sh -c "curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -" && \
    apt install -yy nodejs inotify-tools && \
    mkdir /opt/application
COPY . /opt/application
WORKDIR /opt/application

RUN mix local.hex --force && \
    mix local.rebar --force

RUN mix do compile

RUN MIX_ENV=prod mix release

EXPOSE 4000

ENTRYPOINT _build/$ENV_RELEASE/rel/exsemantica/bin/exsemantica start
