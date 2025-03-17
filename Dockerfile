FROM golang:1.24

WORKDIR /app

RUN go install github.com/phochste/go-ldn-inbox/src/ldn-consumer@latest
RUN go install github.com/phochste/go-ldn-inbox/src/ldn-receiver@latest
RUN go install github.com/phochste/go-ldn-inbox/src/ldn-sender@latest
RUN go install github.com/wabarc/wayback/cmd/wayback@latest
RUN go install github.com/blackducksoftware/exponential-backoff-tool@latest

FROM node:20

COPY --from=0 /go/bin /usr/local/bin

ENV NODE_ENV=production

WORKDIR /app

RUN wget -O /bin/jq https://github.com/stedolan/jq/releases/download/jq-1.5/jq-linux64 

RUN chmod 755 /bin/jq

COPY . .

COPY docker/uuidgen /usr/local/bin/uuidgen

RUN chmod 755 /usr/local/bin/uuidgen

COPY ecosystem.config.js-docker ecosystem.config.js

RUN npm install -g pm2

RUN  mkdir inbox error tmp

EXPOSE 3006

CMD [ "pm2-runtime" , "start", "ecosystem.config.js" ]