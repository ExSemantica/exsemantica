# Copyright 2019-2022 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
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
