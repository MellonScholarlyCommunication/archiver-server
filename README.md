# Archiver Service

An [Event Notifications](https://www.eventnotifications.net) based implementation of an Web archiving service.

This service is a collection of Bash scripts to run a small Web archiving services that can be triggered by sending LDN+AS2 `Offer` messages to an LDN Inbox.

## Dependencies

```
go install github.com/phochste/go-ldn-inbox/src/ldn-consumer@latest
go install github.com/phochste/go-ldn-inbox/src/ldn-receiver@latest
go install github.com/phochste/go-ldn-inbox/src/ldn-sender@latest
go install github.com/wabarc/wayback/cmd/wayback@latest
go install github.com/blackducksoftware/exponential-backoff-tool@latest
```

## Start service

```
ldn-receiver --port 4000 
```

## Send an archivation offer

```
ldn-sender http://localhost:3333/inbox/ data/example.jsonld
```

## Run an archiver batch

```
./run.sh
```

## Run as a service

Install dependencies

```
npm install -g pm2
```

Start service

```
pm2 start ecosystem.config.js
```

Stop service

```
pm2 stop ecosystem.config.js
```

Check logs

```
pm2 log
```

## Docker

Build the docker image:

```
docker build . -t hochstenbach/archiver-server:v0.0.1
```

Run the docker image

```
docker container run -p 3002:3002 --rm hochstenbach/archiver-server:v0.0.1
```