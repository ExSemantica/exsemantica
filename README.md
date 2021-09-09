# exsemantica

Open-source microblogging for people with mutual interests.

## Hacktoberfest

Yes, I am open for collaboration with other fellow programmers! Have fun!

## Guidance

Builds upon [the previous eactivitypub](https://github.com/Chlorophytus/eactivitypub-legacy-0.2) repository.

## How to use this?

Have a PostgreSQL database for long data storage, and an AOF Redis store for graph nodes.

## TODOs

- [ ] Actual API JSON-LD handling
- [ ] Interests chaining interests
- [x] Graph database should be backupable
- [x] Graph database should not be in priv directory; try Mnesia or Redis
- [x] Graph database
- [ ] Microblogging posting in interests
- [ ] T&S (Trust and Safety)
- [ ] Authentication probably shouldn't be RSA 4096, puts too much burden on the server.
