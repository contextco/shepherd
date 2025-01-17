FROM golang:1.23.2-alpine3.20

COPY . .

RUN --mount=type=cache,target="/root/.cache/go-build" go build

CMD ./agent

