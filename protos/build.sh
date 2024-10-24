#!/bin/bash

grpc_tools_ruby_protoc -I ./protos --ruby_out=web/lib/generated/protos --grpc_out=web/lib/generated/grpc ./protos/service.proto
