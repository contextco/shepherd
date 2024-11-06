// Code generated by protoc-gen-go. DO NOT EDIT.
// versions:
// 	protoc-gen-go v1.34.2
// 	protoc        (unknown)
// source: sidecar.proto

package sidecar_pb

import (
	protoreflect "google.golang.org/protobuf/reflect/protoreflect"
	protoimpl "google.golang.org/protobuf/runtime/protoimpl"
	reflect "reflect"
	sync "sync"
)

const (
	// Verify that this generated code is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(20 - protoimpl.MinVersion)
	// Verify that runtime/protoimpl is sufficiently up-to-date.
	_ = protoimpl.EnforceVersion(protoimpl.MaxVersion - 20)
)

type PublishChartRequest struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Chart               *ChartParams `protobuf:"bytes,1,opt,name=chart,proto3" json:"chart,omitempty"`
	RepositoryDirectory string       `protobuf:"bytes,2,opt,name=repository_directory,json=repositoryDirectory,proto3" json:"repository_directory,omitempty"`
}

func (x *PublishChartRequest) Reset() {
	*x = PublishChartRequest{}
	if protoimpl.UnsafeEnabled {
		mi := &file_sidecar_proto_msgTypes[0]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *PublishChartRequest) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*PublishChartRequest) ProtoMessage() {}

func (x *PublishChartRequest) ProtoReflect() protoreflect.Message {
	mi := &file_sidecar_proto_msgTypes[0]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use PublishChartRequest.ProtoReflect.Descriptor instead.
func (*PublishChartRequest) Descriptor() ([]byte, []int) {
	return file_sidecar_proto_rawDescGZIP(), []int{0}
}

func (x *PublishChartRequest) GetChart() *ChartParams {
	if x != nil {
		return x.Chart
	}
	return nil
}

func (x *PublishChartRequest) GetRepositoryDirectory() string {
	if x != nil {
		return x.RepositoryDirectory
	}
	return ""
}

type PublishChartResponse struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields
}

func (x *PublishChartResponse) Reset() {
	*x = PublishChartResponse{}
	if protoimpl.UnsafeEnabled {
		mi := &file_sidecar_proto_msgTypes[1]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *PublishChartResponse) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*PublishChartResponse) ProtoMessage() {}

func (x *PublishChartResponse) ProtoReflect() protoreflect.Message {
	mi := &file_sidecar_proto_msgTypes[1]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use PublishChartResponse.ProtoReflect.Descriptor instead.
func (*PublishChartResponse) Descriptor() ([]byte, []int) {
	return file_sidecar_proto_rawDescGZIP(), []int{1}
}

type ValidateChartRequest struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Chart *ChartParams `protobuf:"bytes,1,opt,name=chart,proto3" json:"chart,omitempty"`
}

func (x *ValidateChartRequest) Reset() {
	*x = ValidateChartRequest{}
	if protoimpl.UnsafeEnabled {
		mi := &file_sidecar_proto_msgTypes[2]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *ValidateChartRequest) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*ValidateChartRequest) ProtoMessage() {}

func (x *ValidateChartRequest) ProtoReflect() protoreflect.Message {
	mi := &file_sidecar_proto_msgTypes[2]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use ValidateChartRequest.ProtoReflect.Descriptor instead.
func (*ValidateChartRequest) Descriptor() ([]byte, []int) {
	return file_sidecar_proto_rawDescGZIP(), []int{2}
}

func (x *ValidateChartRequest) GetChart() *ChartParams {
	if x != nil {
		return x.Chart
	}
	return nil
}

type ValidateChartResponse struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Valid  bool     `protobuf:"varint,1,opt,name=valid,proto3" json:"valid,omitempty"`
	Errors []string `protobuf:"bytes,2,rep,name=errors,proto3" json:"errors,omitempty"`
}

func (x *ValidateChartResponse) Reset() {
	*x = ValidateChartResponse{}
	if protoimpl.UnsafeEnabled {
		mi := &file_sidecar_proto_msgTypes[3]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *ValidateChartResponse) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*ValidateChartResponse) ProtoMessage() {}

func (x *ValidateChartResponse) ProtoReflect() protoreflect.Message {
	mi := &file_sidecar_proto_msgTypes[3]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use ValidateChartResponse.ProtoReflect.Descriptor instead.
func (*ValidateChartResponse) Descriptor() ([]byte, []int) {
	return file_sidecar_proto_rawDescGZIP(), []int{3}
}

func (x *ValidateChartResponse) GetValid() bool {
	if x != nil {
		return x.Valid
	}
	return false
}

func (x *ValidateChartResponse) GetErrors() []string {
	if x != nil {
		return x.Errors
	}
	return nil
}

type ChartParams struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Name              string             `protobuf:"bytes,1,opt,name=name,proto3" json:"name,omitempty"`
	Version           string             `protobuf:"bytes,2,opt,name=version,proto3" json:"version,omitempty"`
	Image             *Image             `protobuf:"bytes,3,opt,name=image,proto3" json:"image,omitempty"`
	EnvironmentConfig *EnvironmentConfig `protobuf:"bytes,4,opt,name=environment_config,json=environmentConfig,proto3" json:"environment_config,omitempty"`
}

func (x *ChartParams) Reset() {
	*x = ChartParams{}
	if protoimpl.UnsafeEnabled {
		mi := &file_sidecar_proto_msgTypes[4]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *ChartParams) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*ChartParams) ProtoMessage() {}

func (x *ChartParams) ProtoReflect() protoreflect.Message {
	mi := &file_sidecar_proto_msgTypes[4]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use ChartParams.ProtoReflect.Descriptor instead.
func (*ChartParams) Descriptor() ([]byte, []int) {
	return file_sidecar_proto_rawDescGZIP(), []int{4}
}

func (x *ChartParams) GetName() string {
	if x != nil {
		return x.Name
	}
	return ""
}

func (x *ChartParams) GetVersion() string {
	if x != nil {
		return x.Version
	}
	return ""
}

func (x *ChartParams) GetImage() *Image {
	if x != nil {
		return x.Image
	}
	return nil
}

func (x *ChartParams) GetEnvironmentConfig() *EnvironmentConfig {
	if x != nil {
		return x.EnvironmentConfig
	}
	return nil
}

type EnvironmentConfig struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	// Contains environment key and value pairs that are hardcoded into the chart.
	EnvironmentVariables []*EnvironmentVariable `protobuf:"bytes,1,rep,name=environment_variables,json=environmentVariables,proto3" json:"environment_variables,omitempty"`
}

func (x *EnvironmentConfig) Reset() {
	*x = EnvironmentConfig{}
	if protoimpl.UnsafeEnabled {
		mi := &file_sidecar_proto_msgTypes[5]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *EnvironmentConfig) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*EnvironmentConfig) ProtoMessage() {}

func (x *EnvironmentConfig) ProtoReflect() protoreflect.Message {
	mi := &file_sidecar_proto_msgTypes[5]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use EnvironmentConfig.ProtoReflect.Descriptor instead.
func (*EnvironmentConfig) Descriptor() ([]byte, []int) {
	return file_sidecar_proto_rawDescGZIP(), []int{5}
}

func (x *EnvironmentConfig) GetEnvironmentVariables() []*EnvironmentVariable {
	if x != nil {
		return x.EnvironmentVariables
	}
	return nil
}

type EnvironmentVariable struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Name  string `protobuf:"bytes,1,opt,name=name,proto3" json:"name,omitempty"`
	Value string `protobuf:"bytes,2,opt,name=value,proto3" json:"value,omitempty"`
}

func (x *EnvironmentVariable) Reset() {
	*x = EnvironmentVariable{}
	if protoimpl.UnsafeEnabled {
		mi := &file_sidecar_proto_msgTypes[6]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *EnvironmentVariable) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*EnvironmentVariable) ProtoMessage() {}

func (x *EnvironmentVariable) ProtoReflect() protoreflect.Message {
	mi := &file_sidecar_proto_msgTypes[6]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use EnvironmentVariable.ProtoReflect.Descriptor instead.
func (*EnvironmentVariable) Descriptor() ([]byte, []int) {
	return file_sidecar_proto_rawDescGZIP(), []int{6}
}

func (x *EnvironmentVariable) GetName() string {
	if x != nil {
		return x.Name
	}
	return ""
}

func (x *EnvironmentVariable) GetValue() string {
	if x != nil {
		return x.Value
	}
	return ""
}

type Image struct {
	state         protoimpl.MessageState
	sizeCache     protoimpl.SizeCache
	unknownFields protoimpl.UnknownFields

	Name string `protobuf:"bytes,1,opt,name=name,proto3" json:"name,omitempty"`
	Tag  string `protobuf:"bytes,2,opt,name=tag,proto3" json:"tag,omitempty"`
}

func (x *Image) Reset() {
	*x = Image{}
	if protoimpl.UnsafeEnabled {
		mi := &file_sidecar_proto_msgTypes[7]
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		ms.StoreMessageInfo(mi)
	}
}

func (x *Image) String() string {
	return protoimpl.X.MessageStringOf(x)
}

func (*Image) ProtoMessage() {}

func (x *Image) ProtoReflect() protoreflect.Message {
	mi := &file_sidecar_proto_msgTypes[7]
	if protoimpl.UnsafeEnabled && x != nil {
		ms := protoimpl.X.MessageStateOf(protoimpl.Pointer(x))
		if ms.LoadMessageInfo() == nil {
			ms.StoreMessageInfo(mi)
		}
		return ms
	}
	return mi.MessageOf(x)
}

// Deprecated: Use Image.ProtoReflect.Descriptor instead.
func (*Image) Descriptor() ([]byte, []int) {
	return file_sidecar_proto_rawDescGZIP(), []int{7}
}

func (x *Image) GetName() string {
	if x != nil {
		return x.Name
	}
	return ""
}

func (x *Image) GetTag() string {
	if x != nil {
		return x.Tag
	}
	return ""
}

var File_sidecar_proto protoreflect.FileDescriptor

var file_sidecar_proto_rawDesc = []byte{
	0x0a, 0x0d, 0x73, 0x69, 0x64, 0x65, 0x63, 0x61, 0x72, 0x2e, 0x70, 0x72, 0x6f, 0x74, 0x6f, 0x22,
	0x6c, 0x0a, 0x13, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x73, 0x68, 0x43, 0x68, 0x61, 0x72, 0x74, 0x52,
	0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x12, 0x22, 0x0a, 0x05, 0x63, 0x68, 0x61, 0x72, 0x74, 0x18,
	0x01, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x0c, 0x2e, 0x43, 0x68, 0x61, 0x72, 0x74, 0x50, 0x61, 0x72,
	0x61, 0x6d, 0x73, 0x52, 0x05, 0x63, 0x68, 0x61, 0x72, 0x74, 0x12, 0x31, 0x0a, 0x14, 0x72, 0x65,
	0x70, 0x6f, 0x73, 0x69, 0x74, 0x6f, 0x72, 0x79, 0x5f, 0x64, 0x69, 0x72, 0x65, 0x63, 0x74, 0x6f,
	0x72, 0x79, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x13, 0x72, 0x65, 0x70, 0x6f, 0x73, 0x69,
	0x74, 0x6f, 0x72, 0x79, 0x44, 0x69, 0x72, 0x65, 0x63, 0x74, 0x6f, 0x72, 0x79, 0x22, 0x16, 0x0a,
	0x14, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x73, 0x68, 0x43, 0x68, 0x61, 0x72, 0x74, 0x52, 0x65, 0x73,
	0x70, 0x6f, 0x6e, 0x73, 0x65, 0x22, 0x3a, 0x0a, 0x14, 0x56, 0x61, 0x6c, 0x69, 0x64, 0x61, 0x74,
	0x65, 0x43, 0x68, 0x61, 0x72, 0x74, 0x52, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x12, 0x22, 0x0a,
	0x05, 0x63, 0x68, 0x61, 0x72, 0x74, 0x18, 0x01, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x0c, 0x2e, 0x43,
	0x68, 0x61, 0x72, 0x74, 0x50, 0x61, 0x72, 0x61, 0x6d, 0x73, 0x52, 0x05, 0x63, 0x68, 0x61, 0x72,
	0x74, 0x22, 0x45, 0x0a, 0x15, 0x56, 0x61, 0x6c, 0x69, 0x64, 0x61, 0x74, 0x65, 0x43, 0x68, 0x61,
	0x72, 0x74, 0x52, 0x65, 0x73, 0x70, 0x6f, 0x6e, 0x73, 0x65, 0x12, 0x14, 0x0a, 0x05, 0x76, 0x61,
	0x6c, 0x69, 0x64, 0x18, 0x01, 0x20, 0x01, 0x28, 0x08, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x69, 0x64,
	0x12, 0x16, 0x0a, 0x06, 0x65, 0x72, 0x72, 0x6f, 0x72, 0x73, 0x18, 0x02, 0x20, 0x03, 0x28, 0x09,
	0x52, 0x06, 0x65, 0x72, 0x72, 0x6f, 0x72, 0x73, 0x22, 0x9c, 0x01, 0x0a, 0x0b, 0x43, 0x68, 0x61,
	0x72, 0x74, 0x50, 0x61, 0x72, 0x61, 0x6d, 0x73, 0x12, 0x12, 0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65,
	0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x12, 0x18, 0x0a, 0x07,
	0x76, 0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x18, 0x02, 0x20, 0x01, 0x28, 0x09, 0x52, 0x07, 0x76,
	0x65, 0x72, 0x73, 0x69, 0x6f, 0x6e, 0x12, 0x1c, 0x0a, 0x05, 0x69, 0x6d, 0x61, 0x67, 0x65, 0x18,
	0x03, 0x20, 0x01, 0x28, 0x0b, 0x32, 0x06, 0x2e, 0x49, 0x6d, 0x61, 0x67, 0x65, 0x52, 0x05, 0x69,
	0x6d, 0x61, 0x67, 0x65, 0x12, 0x41, 0x0a, 0x12, 0x65, 0x6e, 0x76, 0x69, 0x72, 0x6f, 0x6e, 0x6d,
	0x65, 0x6e, 0x74, 0x5f, 0x63, 0x6f, 0x6e, 0x66, 0x69, 0x67, 0x18, 0x04, 0x20, 0x01, 0x28, 0x0b,
	0x32, 0x12, 0x2e, 0x45, 0x6e, 0x76, 0x69, 0x72, 0x6f, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x43, 0x6f,
	0x6e, 0x66, 0x69, 0x67, 0x52, 0x11, 0x65, 0x6e, 0x76, 0x69, 0x72, 0x6f, 0x6e, 0x6d, 0x65, 0x6e,
	0x74, 0x43, 0x6f, 0x6e, 0x66, 0x69, 0x67, 0x22, 0x5e, 0x0a, 0x11, 0x45, 0x6e, 0x76, 0x69, 0x72,
	0x6f, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x43, 0x6f, 0x6e, 0x66, 0x69, 0x67, 0x12, 0x49, 0x0a, 0x15,
	0x65, 0x6e, 0x76, 0x69, 0x72, 0x6f, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x5f, 0x76, 0x61, 0x72, 0x69,
	0x61, 0x62, 0x6c, 0x65, 0x73, 0x18, 0x01, 0x20, 0x03, 0x28, 0x0b, 0x32, 0x14, 0x2e, 0x45, 0x6e,
	0x76, 0x69, 0x72, 0x6f, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x56, 0x61, 0x72, 0x69, 0x61, 0x62, 0x6c,
	0x65, 0x52, 0x14, 0x65, 0x6e, 0x76, 0x69, 0x72, 0x6f, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x56, 0x61,
	0x72, 0x69, 0x61, 0x62, 0x6c, 0x65, 0x73, 0x22, 0x3f, 0x0a, 0x13, 0x45, 0x6e, 0x76, 0x69, 0x72,
	0x6f, 0x6e, 0x6d, 0x65, 0x6e, 0x74, 0x56, 0x61, 0x72, 0x69, 0x61, 0x62, 0x6c, 0x65, 0x12, 0x12,
	0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52, 0x04, 0x6e, 0x61,
	0x6d, 0x65, 0x12, 0x14, 0x0a, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x18, 0x02, 0x20, 0x01, 0x28,
	0x09, 0x52, 0x05, 0x76, 0x61, 0x6c, 0x75, 0x65, 0x22, 0x2d, 0x0a, 0x05, 0x49, 0x6d, 0x61, 0x67,
	0x65, 0x12, 0x12, 0x0a, 0x04, 0x6e, 0x61, 0x6d, 0x65, 0x18, 0x01, 0x20, 0x01, 0x28, 0x09, 0x52,
	0x04, 0x6e, 0x61, 0x6d, 0x65, 0x12, 0x10, 0x0a, 0x03, 0x74, 0x61, 0x67, 0x18, 0x02, 0x20, 0x01,
	0x28, 0x09, 0x52, 0x03, 0x74, 0x61, 0x67, 0x32, 0x8a, 0x01, 0x0a, 0x07, 0x53, 0x69, 0x64, 0x65,
	0x63, 0x61, 0x72, 0x12, 0x3d, 0x0a, 0x0c, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x73, 0x68, 0x43, 0x68,
	0x61, 0x72, 0x74, 0x12, 0x14, 0x2e, 0x50, 0x75, 0x62, 0x6c, 0x69, 0x73, 0x68, 0x43, 0x68, 0x61,
	0x72, 0x74, 0x52, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x1a, 0x15, 0x2e, 0x50, 0x75, 0x62, 0x6c,
	0x69, 0x73, 0x68, 0x43, 0x68, 0x61, 0x72, 0x74, 0x52, 0x65, 0x73, 0x70, 0x6f, 0x6e, 0x73, 0x65,
	0x22, 0x00, 0x12, 0x40, 0x0a, 0x0d, 0x56, 0x61, 0x6c, 0x69, 0x64, 0x61, 0x74, 0x65, 0x43, 0x68,
	0x61, 0x72, 0x74, 0x12, 0x15, 0x2e, 0x56, 0x61, 0x6c, 0x69, 0x64, 0x61, 0x74, 0x65, 0x43, 0x68,
	0x61, 0x72, 0x74, 0x52, 0x65, 0x71, 0x75, 0x65, 0x73, 0x74, 0x1a, 0x16, 0x2e, 0x56, 0x61, 0x6c,
	0x69, 0x64, 0x61, 0x74, 0x65, 0x43, 0x68, 0x61, 0x72, 0x74, 0x52, 0x65, 0x73, 0x70, 0x6f, 0x6e,
	0x73, 0x65, 0x22, 0x00, 0x42, 0x16, 0x5a, 0x14, 0x67, 0x65, 0x6e, 0x65, 0x72, 0x61, 0x74, 0x65,
	0x64, 0x2f, 0x73, 0x69, 0x64, 0x65, 0x63, 0x61, 0x72, 0x5f, 0x70, 0x62, 0x62, 0x06, 0x70, 0x72,
	0x6f, 0x74, 0x6f, 0x33,
}

var (
	file_sidecar_proto_rawDescOnce sync.Once
	file_sidecar_proto_rawDescData = file_sidecar_proto_rawDesc
)

func file_sidecar_proto_rawDescGZIP() []byte {
	file_sidecar_proto_rawDescOnce.Do(func() {
		file_sidecar_proto_rawDescData = protoimpl.X.CompressGZIP(file_sidecar_proto_rawDescData)
	})
	return file_sidecar_proto_rawDescData
}

var file_sidecar_proto_msgTypes = make([]protoimpl.MessageInfo, 8)
var file_sidecar_proto_goTypes = []any{
	(*PublishChartRequest)(nil),   // 0: PublishChartRequest
	(*PublishChartResponse)(nil),  // 1: PublishChartResponse
	(*ValidateChartRequest)(nil),  // 2: ValidateChartRequest
	(*ValidateChartResponse)(nil), // 3: ValidateChartResponse
	(*ChartParams)(nil),           // 4: ChartParams
	(*EnvironmentConfig)(nil),     // 5: EnvironmentConfig
	(*EnvironmentVariable)(nil),   // 6: EnvironmentVariable
	(*Image)(nil),                 // 7: Image
}
var file_sidecar_proto_depIdxs = []int32{
	4, // 0: PublishChartRequest.chart:type_name -> ChartParams
	4, // 1: ValidateChartRequest.chart:type_name -> ChartParams
	7, // 2: ChartParams.image:type_name -> Image
	5, // 3: ChartParams.environment_config:type_name -> EnvironmentConfig
	6, // 4: EnvironmentConfig.environment_variables:type_name -> EnvironmentVariable
	0, // 5: Sidecar.PublishChart:input_type -> PublishChartRequest
	2, // 6: Sidecar.ValidateChart:input_type -> ValidateChartRequest
	1, // 7: Sidecar.PublishChart:output_type -> PublishChartResponse
	3, // 8: Sidecar.ValidateChart:output_type -> ValidateChartResponse
	7, // [7:9] is the sub-list for method output_type
	5, // [5:7] is the sub-list for method input_type
	5, // [5:5] is the sub-list for extension type_name
	5, // [5:5] is the sub-list for extension extendee
	0, // [0:5] is the sub-list for field type_name
}

func init() { file_sidecar_proto_init() }
func file_sidecar_proto_init() {
	if File_sidecar_proto != nil {
		return
	}
	if !protoimpl.UnsafeEnabled {
		file_sidecar_proto_msgTypes[0].Exporter = func(v any, i int) any {
			switch v := v.(*PublishChartRequest); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_sidecar_proto_msgTypes[1].Exporter = func(v any, i int) any {
			switch v := v.(*PublishChartResponse); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_sidecar_proto_msgTypes[2].Exporter = func(v any, i int) any {
			switch v := v.(*ValidateChartRequest); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_sidecar_proto_msgTypes[3].Exporter = func(v any, i int) any {
			switch v := v.(*ValidateChartResponse); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_sidecar_proto_msgTypes[4].Exporter = func(v any, i int) any {
			switch v := v.(*ChartParams); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_sidecar_proto_msgTypes[5].Exporter = func(v any, i int) any {
			switch v := v.(*EnvironmentConfig); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_sidecar_proto_msgTypes[6].Exporter = func(v any, i int) any {
			switch v := v.(*EnvironmentVariable); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
		file_sidecar_proto_msgTypes[7].Exporter = func(v any, i int) any {
			switch v := v.(*Image); i {
			case 0:
				return &v.state
			case 1:
				return &v.sizeCache
			case 2:
				return &v.unknownFields
			default:
				return nil
			}
		}
	}
	type x struct{}
	out := protoimpl.TypeBuilder{
		File: protoimpl.DescBuilder{
			GoPackagePath: reflect.TypeOf(x{}).PkgPath(),
			RawDescriptor: file_sidecar_proto_rawDesc,
			NumEnums:      0,
			NumMessages:   8,
			NumExtensions: 0,
			NumServices:   1,
		},
		GoTypes:           file_sidecar_proto_goTypes,
		DependencyIndexes: file_sidecar_proto_depIdxs,
		MessageInfos:      file_sidecar_proto_msgTypes,
	}.Build()
	File_sidecar_proto = out.File
	file_sidecar_proto_rawDesc = nil
	file_sidecar_proto_goTypes = nil
	file_sidecar_proto_depIdxs = nil
}
