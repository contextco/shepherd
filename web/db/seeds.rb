# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

t = Team.create!

%w[alex alec].each do |name|
  User.create_with(team: t, password: 'password', name:).find_or_create_by!(email: "#{name}@context.ai")
end

d = t.deployments.create!(name: 'sample deployment')

def create_containers(name, lifecycle_ids, deployment)
  lifecycle_ids.each do |lifecycle_id|
    container = deployment.containers.create!(name:, lifecycle_id:)
    rand(1..10).times { container.event_logs.create!(event_type: :heartbeat) }
  end
end

create_containers('web', %w[1234 5678], d)
create_containers('worker', %w[45222 234234], d)

p = t.projects.create!(name: 'sample project')

v = p.project_versions.create!(description: 'sample version', version: FFaker::SemVer.rand)
v.services.create!(name: 'web', image: 'nginx:alpine', cpu_cores: 2, memory_bytes: 2.gigabytes)
54.times do
  v = v.fork!(description: FFaker::Lorem.sentence, version: FFaker::SemVer.next(v.version))
end
