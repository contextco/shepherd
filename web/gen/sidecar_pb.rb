# frozen_string_literal: true
# Generated by the protocol buffer compiler.  DO NOT EDIT!
# source: sidecar.proto

require 'google/protobuf'

require 'google/protobuf/struct_pb'


descriptor_data = "\n\rsidecar.proto\x12\x07sidecar\x1a\x1cgoogle/protobuf/struct.proto\"t\n\x13PublishChartRequest\x12*\n\x05\x63hart\x18\x01 \x01(\x0b\x32\x14.sidecar.ChartParamsR\x05\x63hart\x12\x31\n\x14repository_directory\x18\x02 \x01(\tR\x13repositoryDirectory\"\x16\n\x14PublishChartResponse\"B\n\x14ValidateChartRequest\x12*\n\x05\x63hart\x18\x01 \x01(\x0b\x32\x14.sidecar.ChartParamsR\x05\x63hart\"E\n\x15ValidateChartResponse\x12\x14\n\x05valid\x18\x01 \x01(\x08R\x05valid\x12\x16\n\x06\x65rrors\x18\x02 \x03(\tR\x06\x65rrors\"\xb4\x01\n\x0b\x43hartParams\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\x18\n\x07version\x18\x02 \x01(\tR\x07version\x12\x32\n\x08services\x18\x07 \x03(\x0b\x32\x16.sidecar.ServiceParamsR\x08services\x12=\n\x0c\x64\x65pendencies\x18\x08 \x03(\x0b\x32\x19.sidecar.DependencyParamsR\x0c\x64\x65pendenciesJ\x04\x08\x03\x10\x07\"\xc1\x01\n\x10\x44\x65pendencyParams\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12!\n\x0cvalues_alias\x18\x05 \x01(\tR\x0bvaluesAlias\x12\x18\n\x07version\x18\x02 \x01(\tR\x07version\x12%\n\x0erepository_url\x18\x03 \x01(\tR\rrepositoryUrl\x12\x35\n\toverrides\x18\x04 \x03(\x0b\x32\x17.sidecar.OverrideParamsR\toverrides\"R\n\x0eOverrideParams\x12\x12\n\x04path\x18\x01 \x01(\tR\x04path\x12,\n\x05value\x18\x02 \x01(\x0b\x32\x16.google.protobuf.ValueR\x05value\"\xf1\x03\n\rServiceParams\x12\x12\n\x04name\x18\x06 \x01(\tR\x04name\x12#\n\rreplica_count\x18\x01 \x01(\x05R\x0creplicaCount\x12$\n\x05image\x18\x02 \x01(\x0b\x32\x0e.sidecar.ImageR\x05image\x12\x30\n\tresources\x18\x03 \x01(\x0b\x32\x12.sidecar.ResourcesR\tresources\x12I\n\x12\x65nvironment_config\x18\x04 \x01(\x0b\x32\x1a.sidecar.EnvironmentConfigR\x11\x65nvironmentConfig\x12/\n\tendpoints\x18\x05 \x03(\x0b\x32\x11.sidecar.EndpointR\tendpoints\x12\x34\n\x0binit_config\x18\x07 \x01(\x0b\x32\x13.sidecar.InitConfigR\ninitConfig\x12^\n\x18persistent_volume_claims\x18\x08 \x03(\x0b\x32$.sidecar.PersistentVolumeClaimParamsR\x16persistentVolumeClaims\x12=\n\x0eingress_config\x18\t \x01(\x0b\x32\x16.sidecar.IngressParamsR\ringressConfig\"_\n\rIngressParams\x12:\n\npreference\x18\x03 \x01(\x0e\x32\x1a.sidecar.IngressPreferenceR\npreference\x12\x12\n\x04port\x18\x04 \x01(\x05R\x04port\"+\n\x15\x45xternalIngressParams\x12\x12\n\x04port\x18\x01 \x01(\x05R\x04port\"\x17\n\x15InternalIngressParams\"d\n\x1bPersistentVolumeClaimParams\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\x1d\n\nsize_bytes\x18\x02 \x01(\x03R\tsizeBytes\x12\x12\n\x04path\x18\x03 \x01(\tR\x04path\"1\n\nInitConfig\x12#\n\rinit_commands\x18\x01 \x03(\tR\x0cinitCommands\"\x1e\n\x08\x45ndpoint\x12\x12\n\x04port\x18\x01 \x01(\x05R\x04port\"\x91\x01\n\x11\x45nvironmentConfig\x12Q\n\x15\x65nvironment_variables\x18\x01 \x03(\x0b\x32\x1c.sidecar.EnvironmentVariableR\x14\x65nvironmentVariables\x12)\n\x07secrets\x18\x03 \x03(\x0b\x32\x0f.sidecar.SecretR\x07secrets\"E\n\x06Secret\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\'\n\x0f\x65nvironment_key\x18\x02 \x01(\tR\x0e\x65nvironmentKey\"?\n\x13\x45nvironmentVariable\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\x14\n\x05value\x18\x02 \x01(\tR\x05value\"\xa3\x01\n\x05Image\x12\x12\n\x04name\x18\x01 \x01(\tR\x04name\x12\x10\n\x03tag\x18\x02 \x01(\tR\x03tag\x12\x39\n\ncredential\x18\x03 \x01(\x0b\x32\x19.sidecar.ImageCredentialsR\ncredential\x12\x39\n\x0bpull_policy\x18\x04 \x01(\x0e\x32\x18.sidecar.ImagePullPolicyR\npullPolicy\"J\n\x10ImageCredentials\x12\x1a\n\x08username\x18\x01 \x01(\tR\x08username\x12\x1a\n\x08password\x18\x02 \x01(\tR\x08password\"\xc7\x01\n\tResources\x12.\n\x13\x63pu_cores_requested\x18\x01 \x01(\x05R\x11\x63puCoresRequested\x12&\n\x0f\x63pu_cores_limit\x18\x02 \x01(\x05R\rcpuCoresLimit\x12\x34\n\x16memory_bytes_requested\x18\x03 \x01(\x03R\x14memoryBytesRequested\x12,\n\x12memory_bytes_limit\x18\x04 \x01(\x03R\x10memoryBytesLimit*=\n\x11IngressPreference\x12\x13\n\x0fPREFER_EXTERNAL\x10\x00\x12\x13\n\x0fPREFER_INTERNAL\x10\x01*r\n\x0fImagePullPolicy\x12\x1c\n\x18IMAGE_PULL_POLICY_ALWAYS\x10\x00\x12$\n IMAGE_PULL_POLICY_IF_NOT_PRESENT\x10\x01\x12\x1b\n\x17IMAGE_PULL_POLICY_NEVER\x10\x02\x32\xaa\x01\n\x07Sidecar\x12M\n\x0cPublishChart\x12\x1c.sidecar.PublishChartRequest\x1a\x1d.sidecar.PublishChartResponse\"\x00\x12P\n\rValidateChart\x12\x1d.sidecar.ValidateChartRequest\x1a\x1e.sidecar.ValidateChartResponse\"\x00\x42\x16Z\x14generated/sidecar_pbb\x06proto3"

pool = Google::Protobuf::DescriptorPool.generated_pool
pool.add_serialized_file(descriptor_data)

module Sidecar
  PublishChartRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.PublishChartRequest").msgclass
  PublishChartResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.PublishChartResponse").msgclass
  ValidateChartRequest = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.ValidateChartRequest").msgclass
  ValidateChartResponse = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.ValidateChartResponse").msgclass
  ChartParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.ChartParams").msgclass
  DependencyParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.DependencyParams").msgclass
  OverrideParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.OverrideParams").msgclass
  ServiceParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.ServiceParams").msgclass
  IngressParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.IngressParams").msgclass
  ExternalIngressParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.ExternalIngressParams").msgclass
  InternalIngressParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.InternalIngressParams").msgclass
  PersistentVolumeClaimParams = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.PersistentVolumeClaimParams").msgclass
  InitConfig = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.InitConfig").msgclass
  Endpoint = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.Endpoint").msgclass
  EnvironmentConfig = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.EnvironmentConfig").msgclass
  Secret = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.Secret").msgclass
  EnvironmentVariable = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.EnvironmentVariable").msgclass
  Image = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.Image").msgclass
  ImageCredentials = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.ImageCredentials").msgclass
  Resources = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.Resources").msgclass
  IngressPreference = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.IngressPreference").enummodule
  ImagePullPolicy = ::Google::Protobuf::DescriptorPool.generated_pool.lookup("sidecar.ImagePullPolicy").enummodule
end
