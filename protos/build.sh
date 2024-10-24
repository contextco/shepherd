#!/bin/bash

grpc_tools_ruby_protoc -I ./protos --ruby_out=web/lib/generated/protos --grpc_out=web/lib/generated/grpc ./protos/service.proto
protoc --go_out=./client/generated --go_opt=paths=source_relative --go-grpc_out=./client/generated --go-grpc_opt=paths=source_relative ./protos/service.proto
