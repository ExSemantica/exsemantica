# exsemantica

The backend of ExSemantica, an open-source link aggregator.

## Guidance

Builds upon [the previous eactivitypub][eactivitypub] repository.
This is a mix of incomplete pieces `v0.7` (a Phoenix 1.5 monolithic codebase) and `v0.8` (using Mnesia).
Together these make a great concept for a simple, reliable social platform at edge.
This is what I see and hope in `v0.10`, but failure is okay.

## How to use this?

### Developing

The database is a PostgreSQL storage. You can use Docker (or Podman) to run it.

```shell
$ docker run -p 5432:5432 --name exsemantica-postgres -e POSTGRES_PASSWORD=postgres -d postgres:alpine
```

The PostgreSQL database should be initialized in first use.

```shell
$ mix ecto.reset
```

Start the backend API and other services.

```shell
$ iex -S mix
```

#### Creating and logging in as a user

Create the example user

```elixir
iex> Exsemantica.Administration.User.create("example", "test_password", "user@example.com", "I'm a tester")
```

Try to log in with the example user

```shell
$ curl -H 'Content-Type: application/json' -X POST -d '{"username":"example","password":"test_password"}' http://localhost:4000/authentication/log_in
```

If the JSON response's `e` is `"OK"`, then you have successfully logged in and that token is valid.

### Deploying

TODO

[eactivitypub]: https://github.com/Chlorophytus/eactivitypub-legacy-0.2
