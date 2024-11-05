package server

import (
	sidecar_pb "sidecar/generated/sidecar_pb"
)

type Server struct {
	sidecar_pb.UnimplementedSidecarServer
}

func New() *Server {
	return &Server{}
}
