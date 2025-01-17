FROM golang:1.23-alpine

COPY . .

RUN --mount=type=cache,target="/root/.cache/go-build" go build -o agentbin

CMD ./agentbin

