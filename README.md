# Installation and running

## Prerequisites

Install [Elixir](https://elixir-lang.org/install.html "Installing Elixir"), [Redis](https://redis.io/download "Download page"), [Docker](https://docs.docker.com/install/ "Docker Engine overview"), [Docker Compose](https://docs.docker.com/compose/install/ "Install Docker Compose").

## Install

`$ git clone https://github.com/kilych/elixir-visited-links.git`

`$ cd elixir-visited-links`

`$ mix deps.get`

`$ mix compile`

## Test

`$  docker-compose up -d`

`$ mix test`

## Run

(Not for a "real" production.)

`$ mix run --no-halt`

Set `MIX_ENV` to prevent `Plug.Debugger` from showing a debugging page:

`$ MIX_ENV=prod mix run --no-halt`
