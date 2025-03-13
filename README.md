# Archiver Service

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