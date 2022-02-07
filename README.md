# exsemantica

Open-source microblogging for people with mutual interests.

## Guidance

Builds upon [the previous eactivitypub][eactivitypub] repository.
This is a mix of incomplete pieces `v0.7` (a Phoenix 1.5 monolithic codebase) and `v0.8` (using Mnesia).
Together these make a great concept for a simple, reliable social platform at edge.
This is what I see and hope in `v0.9`, but failure is okay.

## How to use this?

If you want to fetch packages for frontend, use NodeJS NPM in `assets/` to use Alpine.JS
```shell
$ npm install alpinejs
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
