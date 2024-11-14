// Code generated by protoc-gen-go-grpc. DO NOT EDIT.
// versions:
// - protoc-gen-go-grpc v1.5.1
// - protoc             (unknown)
// source: sidecar.proto

package sidecar_pb

import (
	context "context"
	grpc "google.golang.org/grpc"
	codes "google.golang.org/grpc/codes"
	status "google.golang.org/grpc/status"
)

// This is a compile-time assertion to ensure that this generated file
// is compatible with the grpc package it is being compiled against.
// Requires gRPC-Go v1.64.0 or later.
const _ = grpc.SupportPackageIsVersion9

const (
	Sidecar_PublishChart_FullMethodName  = "/sidecar.Sidecar/PublishChart"
	Sidecar_ValidateChart_FullMethodName = "/sidecar.Sidecar/ValidateChart"
)

// SidecarClient is the client API for Sidecar service.
//
// For semantics around ctx use and closing/ending streaming RPCs, please refer to https://pkg.go.dev/google.golang.org/grpc/?tab=doc#ClientConn.NewStream.
type SidecarClient interface {
	PublishChart(ctx context.Context, in *PublishChartRequest, opts ...grpc.CallOption) (*PublishChartResponse, error)
	ValidateChart(ctx context.Context, in *ValidateChartRequest, opts ...grpc.CallOption) (*ValidateChartResponse, error)
}

type sidecarClient struct {
	cc grpc.ClientConnInterface
}

func NewSidecarClient(cc grpc.ClientConnInterface) SidecarClient {
	return &sidecarClient{cc}
}

func (c *sidecarClient) PublishChart(ctx context.Context, in *PublishChartRequest, opts ...grpc.CallOption) (*PublishChartResponse, error) {
	cOpts := append([]grpc.CallOption{grpc.StaticMethod()}, opts...)
	out := new(PublishChartResponse)
	err := c.cc.Invoke(ctx, Sidecar_PublishChart_FullMethodName, in, out, cOpts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

func (c *sidecarClient) ValidateChart(ctx context.Context, in *ValidateChartRequest, opts ...grpc.CallOption) (*ValidateChartResponse, error) {
	cOpts := append([]grpc.CallOption{grpc.StaticMethod()}, opts...)
	out := new(ValidateChartResponse)
	err := c.cc.Invoke(ctx, Sidecar_ValidateChart_FullMethodName, in, out, cOpts...)
	if err != nil {
		return nil, err
	}
	return out, nil
}

// SidecarServer is the server API for Sidecar service.
// All implementations must embed UnimplementedSidecarServer
// for forward compatibility.
type SidecarServer interface {
	PublishChart(context.Context, *PublishChartRequest) (*PublishChartResponse, error)
	ValidateChart(context.Context, *ValidateChartRequest) (*ValidateChartResponse, error)
	mustEmbedUnimplementedSidecarServer()
}

// UnimplementedSidecarServer must be embedded to have
// forward compatible implementations.
//
// NOTE: this should be embedded by value instead of pointer to avoid a nil
// pointer dereference when methods are called.
type UnimplementedSidecarServer struct{}

func (UnimplementedSidecarServer) PublishChart(context.Context, *PublishChartRequest) (*PublishChartResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method PublishChart not implemented")
}
func (UnimplementedSidecarServer) ValidateChart(context.Context, *ValidateChartRequest) (*ValidateChartResponse, error) {
	return nil, status.Errorf(codes.Unimplemented, "method ValidateChart not implemented")
}
func (UnimplementedSidecarServer) mustEmbedUnimplementedSidecarServer() {}
func (UnimplementedSidecarServer) testEmbeddedByValue()                 {}

// UnsafeSidecarServer may be embedded to opt out of forward compatibility for this service.
// Use of this interface is not recommended, as added methods to SidecarServer will
// result in compilation errors.
type UnsafeSidecarServer interface {
	mustEmbedUnimplementedSidecarServer()
}

func RegisterSidecarServer(s grpc.ServiceRegistrar, srv SidecarServer) {
	// If the following call pancis, it indicates UnimplementedSidecarServer was
	// embedded by pointer and is nil.  This will cause panics if an
	// unimplemented method is ever invoked, so we test this at initialization
	// time to prevent it from happening at runtime later due to I/O.
	if t, ok := srv.(interface{ testEmbeddedByValue() }); ok {
		t.testEmbeddedByValue()
	}
	s.RegisterService(&Sidecar_ServiceDesc, srv)
}

func _Sidecar_PublishChart_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(PublishChartRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(SidecarServer).PublishChart(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Sidecar_PublishChart_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(SidecarServer).PublishChart(ctx, req.(*PublishChartRequest))
	}
	return interceptor(ctx, in, info, handler)
}

func _Sidecar_ValidateChart_Handler(srv interface{}, ctx context.Context, dec func(interface{}) error, interceptor grpc.UnaryServerInterceptor) (interface{}, error) {
	in := new(ValidateChartRequest)
	if err := dec(in); err != nil {
		return nil, err
	}
	if interceptor == nil {
		return srv.(SidecarServer).ValidateChart(ctx, in)
	}
	info := &grpc.UnaryServerInfo{
		Server:     srv,
		FullMethod: Sidecar_ValidateChart_FullMethodName,
	}
	handler := func(ctx context.Context, req interface{}) (interface{}, error) {
		return srv.(SidecarServer).ValidateChart(ctx, req.(*ValidateChartRequest))
	}
	return interceptor(ctx, in, info, handler)
}

// Sidecar_ServiceDesc is the grpc.ServiceDesc for Sidecar service.
// It's only intended for direct use with grpc.RegisterService,
// and not to be introspected or modified (even as a copy)
var Sidecar_ServiceDesc = grpc.ServiceDesc{
	ServiceName: "sidecar.Sidecar",
	HandlerType: (*SidecarServer)(nil),
	Methods: []grpc.MethodDesc{
		{
			MethodName: "PublishChart",
			Handler:    _Sidecar_PublishChart_Handler,
		},
		{
			MethodName: "ValidateChart",
			Handler:    _Sidecar_ValidateChart_Handler,
		},
	},
	Streams:  []grpc.StreamDesc{},
	Metadata: "sidecar.proto",
}
