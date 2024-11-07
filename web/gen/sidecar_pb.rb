# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: sidecar.proto

require 'google/protobuf'


descriptor_data = "\n\rsidecar.proto\"P\n\x13PublishChartRequest\x12\x1b\n\x05\x63hart\x18\x01 \x01(\x0b\x32\x0c.ChartParams\x12\x1c\n\x14repository_directory\x18\x02 \x01(\t\"\x16\n\x14PublishChartResponse\"3\n\x14ValidateChartRequest\x12\x1b\n\x05\x63hart\x18\x01 \x01(\x0b\x32\x0c.ChartParams\"6\n\x15ValidateChartResponse\x12\r\n\x05valid\x18\x01 \x01(\x08\x12\x0e\n\x06\x65rrors\x18\x02 \x03(\t\"s\n\x0b\x43hartParams\x12\x0c\n\x04name\x18\x01 \x01(\t\x12\x0f\n\x07version\x18\x02 \x01(\t\x12\x15\n\x05image\x18\x03 \x01(\x0b\x32\x06.Image\x12.\n\x12\x65nvironment_config\x18\x04 \x01(\x0b\x32\x12.EnvironmentConfig\"H\n\x11\x45nvironmentConfig\x12\x33\n\x15\x65nvironment_variables\x18\x01 \x03(\x0b\x32\x14.EnvironmentVariable\"2\n\x13\x45nvironmentVariable\x12\x0c\n\x04name\x18\x01 \x01(\t\x12\r\n\x05value\x18\x02 \x01(\t\"\"\n\x05Image\x12\x0c\n\x04name\x18\x01 \x01(\t\x12\x0b\n\x03tag\x18\x02 \x01(\t2\x8a\x01\n\x07Sidecar\x12=\n\x0cPublishChart\x12\x14.PublishChartRequest\x1a\x15.PublishChartResponse\"\x00\x12@\n\rValidateChart\x12\x15.ValidateChartRequest\x1a\x16.ValidateChartResponse\"\x00\x42\x16Z\x14generated/sidecar_pbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

PublishChartRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("PublishChartRequest").msgclass
PublishChartResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("PublishChartResponse").msgclass
ValidateChartRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("ValidateChartRequest").msgclass
ValidateChartResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("ValidateChartResponse").msgclass
ChartParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("ChartParams").msgclass
EnvironmentConfig = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("EnvironmentConfig").msgclass
EnvironmentVariable = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("EnvironmentVariable").msgclass
Image = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Image").msgclass
