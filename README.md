# exsemantica

Open-source link aggregator.

## Guidance

Builds upon [the previous eactivitypub][eactivitypub] repository.
This is a mix of incomplete pieces `v0.7` (a Phoenix 1.5 monolithic codebase) and `v0.8` (using Mnesia).
Together these make a great concept for a simple, reliable social platform at edge.
This is what I see and hope in `v0.9`, but failure is okay.

## How to use this?

### Developing

The database is a PostgreSQL storage. You could use Docker or Podman to start it.

```shell
$ podman run --name exsemantica-db -p 5432:5432 -e POSTGRES_PASSWORD=postgres -e POSTGRES_DB=exsemantica_dev -d postgres:16-alpine
```

The PostgreSQL database should be initialized in first use.

```shell
$ mix ecto.reset
```

Start the Phoenix application. You should be able to connect to `http://localhost:4000`.
```shell
$ iex -S mix phx.server
```

### Deploying

TODO

[eactivitypub]: https://github.com/Chlorophytus/eactivitypub-legacy-0.2
