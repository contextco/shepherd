FactoryBot.define do
  factory :user do
    email { FFaker::Internet.email }
    password { 'password' }
  end
end
