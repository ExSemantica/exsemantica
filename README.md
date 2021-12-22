# exsemantica

Open-source microblogging for people with mutual interests.

## Hacktoberfest

Yes, I am open for collaboration with other fellow programmers! Have fun!

## Guidance

Builds upon [the previous eactivitypub](https://github.com/Chlorophytus/eactivitypub-legacy-0.2) repository.

## How to use this?

Have a PostgreSQL database for long data storage, and an AOF Redis store for graph nodes.

```shell
$ docker run --name exsemantica-postgres -p 5432:5432 -e POSTGRES_PASSWORD=postgres -d postgres
$ docker run --name exsemantica-redis -p 6379:6379 -d redis redis-server --appendonly yes
```

If you want to fetch packages for frontend, use NodeJS NPM.
```shell
$ npm install tailwindcss postcss autoprefixer topbar phoenix phoenix_live_view phoenix_html jsrsasign jsrsasign-util --save-dev
```

## TODOs

- [ ] Actual API JSON-LD handling
- [ ] Interests chaining interests
- [x] Graph database should be backupable
- [x] Graph database should not be in priv directory; try Mnesia or Redis
- [x] Graph database
- [ ] Microblogging posting in interests
- [ ] T&S (Trust and Safety)
- [ ] Authentication probably shouldn't be RSA 4096, puts too much burden on the server.
- [ ] IRC protocol based chat system
