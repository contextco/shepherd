namespace :grpc do
  desc "Compile protobuf definitions"
  task compile: :environment do
    proto_path = File.join(Rails.root, "..", "protos")
    output_path = File.join(Rails.root, "gen")

    # Create output directory if it doesn't exist
    FileUtils.mkdir_p(output_path)

    # Find all .proto files
    proto_files = Dir.glob(File.join(proto_path, "*.proto"))

    proto_files.each do |proto_file|
      # Generate Ruby code
      system("grpc_tools_ruby_protoc " \
               "--ruby_out=#{output_path} " \
               "--grpc_out=#{output_path} " \
               "--proto_path=#{proto_path} " \
               "#{proto_file}")

      unless $?.success?
        puts "Failed to compile #{proto_file}"
        exit 1
      end
    end

    puts "Successfully compiled #{proto_files.length} proto files"
  end
end
