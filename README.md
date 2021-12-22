# exsemantica

Open-source microblogging for people with mutual interests.

## Hacktoberfest/other collaboration.

Yes, I am open for collaboration with other fellow programmers! Have fun!

## Guidance

Builds upon [the previous eactivitypub][eactivitypub] repository.

## How to use this?

Have a persistent Redis store for graph nodes. [You may use Docker for this.][redis-on-docker]

If you want to fetch packages for frontend, use NodeJS NPM.
```shell
$ npm install tailwindcss postcss autoprefixer topbar phoenix phoenix_live_view phoenix_html jsrsasign jsrsasign-util --save-dev
```

## TODOs

- [ ] API JSON-LD handling
- [ ] API GraphQL handling
- [ ] Federation: is it possible?
- [ ] Interests chaining interests
- [x] Graph database should be archivable, able to be backed up
- [x] Graph database should not be in priv directory; try Mnesia or Redis
- [x] Graph database
- [ ] Microblogging posting in interests
- [ ] T&S (Trust and Safety)
- [ ] Authentication probably shouldn't be RSA 4096, puts too much burden on the server.
- [ ] IRC protocol based chat system
- [ ] Reimplement frontend/middleware from v0.7, reusing Phoenix.
- [ ] Redo backend from v0.7.

[redis-on-docker]: https://hub.docker.com/_/redis
[eactivitypub]: https://github.com/Chlorophytus/eactivitypub-legacy-0.2
