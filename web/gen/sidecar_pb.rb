# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: sidecar.proto

require 'google/protobuf'


descriptor_data = "\n\rsidecar.proto\"l\n\x13PublishChartRequest\x12\"\n\x05\x63hart\x18\x01 \x01(\x0b\x32\x0c.ChartParamsR\x05\x63hart\x12\x31\n\x14repository_directory\x18\x02 \x01(\tR\x13repositoryDirectory\"\x16\n\x14PublishChartResponse\":\n\x14ValidateChartRequest\x12\"\n\x05\x63hart\x18\x01 \x01(\x0b\x32\x0c.ChartParamsR\x05\x63hart\"E\n\x15ValidateChartResponse\x12\x14\n\x05valid\x18\x01 \x01(\x08R\x05valid\x12\x16\n\x06\x65rrors\x18\x02 \x03(\tR\x06\x65rrors\"\x9c\x01\n\x0b\x43hartParams\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\x18\n\x07version\x18\x02 \x01(\tR\x07version\x12\x1c\n\x05image\x18\x03 \x01(\x0b\x32\x06.ImageR\x05image\x12\x41\n\x12\x65nvironment_config\x18\x04 \x01(\x0b\x32\x12.EnvironmentConfigR\x11\x65nvironmentConfig\"\x81\x01\n\x11\x45nvironmentConfig\x12I\n\x15\x65nvironment_variables\x18\x01 \x03(\x0b\x32\x14.EnvironmentVariableR\x14\x65nvironmentVariables\x12!\n\x07secrets\x18\x03 \x03(\x0b\x32\x07.SecretR\x07secrets\"E\n\x06Secret\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\'\n\x0f\x65nvironment_key\x18\x02 \x01(\tR\x0e\x65nvironmentKey\"?\n\x13\x45nvironmentVariable\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\x14\n\x05value\x18\x02 \x01(\tR\x05value\"-\n\x05Image\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\x10\n\x03tag\x18\x02 \x01(\tR\x03tag2\x8a\x01\n\x07Sidecar\x12=\n\x0cPublishChart\x12\x14.PublishChartRequest\x1a\x15.PublishChartResponse\"\x00\x12@\n\rValidateChart\x12\x15.ValidateChartRequest\x1a\x16.ValidateChartResponse\"\x00\x42\x16Z\x14generated/sidecar_pbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

PublishChartRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("PublishChartRequest").msgclass
PublishChartResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("PublishChartResponse").msgclass
ValidateChartRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("ValidateChartRequest").msgclass
ValidateChartResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("ValidateChartResponse").msgclass
ChartParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("ChartParams").msgclass
EnvironmentConfig = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("EnvironmentConfig").msgclass
Secret = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Secret").msgclass
EnvironmentVariable = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("EnvironmentVariable").msgclass
Image = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("Image").msgclass
