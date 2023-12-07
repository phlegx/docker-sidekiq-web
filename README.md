# docker-sidekiq-web

A Docker image to run a stand-alone instance of Sidekiq Web UI.

Docker Hub Repo: https://hub.docker.com/r/phlegx/sidekiq-web/

## Features

* Use slim-buster, bullseye, buster ruby for the base image
* Uses most recent versions of required gems
* Uses Puma for Rack application
* Uses connection pool for Redis connections
* Redis configuration support
* Redis Sentinel configuration support
* Redis driver ruby and hiredis support
* Sidekiq Cron support
* HTTP Basic Auth support

## Usage

### Build image

```
docker build \
  --build-arg RUBY_VERSION=3.2.2-slim-buster \
  --build-arg SIDEKIQ_VERSION=7.2.0 \
  --build-arg SIDEKIQ_CRON_VERSION=1.11.0 \
  --build-arg PUMA_VERSION=6.4.0 \
  -t sidekiq-web .
```

### Run image

```
docker run \
  -p 3001:9292 \
  -e REDIS_URI=host:6379 \
  sidekiq-web
```

### Sidekiq Cron

To run the container with Sidekiq Cron:

```
docker run \
  -p 3001:9292 \
  -e REDIS_URI=host:6379 \
  -e SIDEKIQ_CRON=true \
  sidekiq-web
```

### Redis Config

To run the container with custom Redis configuration:

```
docker run \
  -p 3001:9292 \
  -e REDIS_URI=host:6379 \
  -e REDIS_DB=1 \
  -e REDIS_POOL_SIZE=5 \
  -e REDIS_PASSWORD=password \
  -e REDIS_DRIVER=ruby \
  sidekiq-web
```

Using Redis Sentinel configuration:

```
docker run \
  -p 3001:9292 \
  -e REDIS_SENTINEL_URIS=uri1,uri2,uri3:26379 \
  -e REDIS_SENTINEL_PORT=26379 \
  -e REDIS_SENTINEL_NAME=mymaster \
  -e REDIS_SENTINEL_PASSWORD=password \
  -e REDIS_PASSWORD=password \
  -e REDIS_DB=1 \
  -e REDIS_POOL_SIZE=5 \
  -e REDIS_DRIVER=ruby \
  sidekiq-web
```

Default `REDIS_DRIVER` is set to `hiredis`.

### HTTP Basic Auth Credentials

To run the container with a custom username and password:

```
docker run \
  -p 3001:9292 \
  -e REDIS_URI=host:6379 \
  -e SIDEKIQ_USERNAME=username \
  -e SIDEKIQ_PASSWORD=password \
  sidekiq-web
```

### Reverse Proxy

To run the container behind a proxy, make sure to set environment variable `SCRIPT_NAME` so that Sidekiq Web UI can properly construct URLs to the necessary CSS/JS assets:

```
docker run \
  -p 3001:9292 \
  -e REDIS_URI=host:6379 \
  -e SCRIPT_NAME=/sidekiq \
  sidekiq-web
```

### Docker Compose

Example compose file:

```
version: '3'
services:
  sidekiq-web:
    image: phlegx/sidekiq-web:r3.2-s7
    environment:
      REDIS_URI: host:6379
      REDIS_PASSWORD: password
      SIDEKIQ_USERNAME: username
      SIDEKIQ_PASSWORD: password
    ports:
      - 3001:9292
```

## Other Implementations

* [clok/standalone-sidekiq-web](https://github.com/clok/standalone-sidekiq-web)
* [maddiefletcher/docker-sidekiqweb](https://github.com/maddiefletcher/docker-sidekiqweb)

## Contributing

1. Fork it ( https://github.com/[your-username]/docker-sidekiq-web/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

The MIT License

Copyright (c) 2023 Phlegx Systems Technologies GmbH
