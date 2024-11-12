FactoryBot.define do
  factory :user do
    email { FFaker::Internet.email }
    password { 'password' }

    team
  end
end
