package main

import (
	"context"
	"log"

	"onprem/config"
	"onprem/control"
	"onprem/process"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	service_pb "onprem/generated/protos"
)

var (
	tsKey = config.Define(
		"ts-key",
		"",
		"The key for the tailscale instance",
	)
)

func do(ctx context.Context) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()

	p, err := process.RunFromArgs(ctx)
	if err != nil && err != process.ErrNoCommand {
		return err
	}
	if p != nil {
		defer p.Cancel()
	}

	conn, err := grpc.DialContext(ctx, "localhost:50051", grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return err
	}
	defer conn.Close()

	_ = service_pb.NewOnPremClient(conn)

	log.Printf("Starting control server with process %v", p)
	ctrl, err := control.New(tsKey.MustValue(), p)
	if err != nil {
		return err
	}
	defer ctrl.Close()

	return ctrl.Start(ctx)
}

func main() {
	config.Init()

	if err := do(context.Background()); err != nil {
		log.Fatalf("Failed to do this %s", err)
	}
}
