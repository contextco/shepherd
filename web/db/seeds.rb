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
  User.create_with(team: t, password: 'password', name:, role: :admin).find_or_create_by!(email: "#{name}@context.ai")
end

v = t.setup_scaffolding!('sample', 'sample project description', :full)
v.services.create!(name: 'web', image: 'nginx:alpine', cpu_cores: 2, memory_bytes: 2.gigabytes)
rand(10..15).times do
  v = v.fork!(description: FFaker::Lorem.sentence, version: FFaker::SemVer.next(v.version))
  v.published! if rand(10) > 5
end
