# Contributing

## Guidelines
- Use [Conventional Commits](https://www.conventionalcommits.org/en/)

## How does it work?

### Redis
The Redis database stores graph connection deltas as an ETF binary.
Think: What is added and removed on each change?
These changes are appended to Redis, which will hopefully get saved later.

### Postgres
The PostgreSQL database stores node metadata.

