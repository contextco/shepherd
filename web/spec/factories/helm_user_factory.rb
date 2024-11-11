FactoryBot.define do
  factory :helm_user do
    name { FFaker::Lorem.word }
    password { FFaker::Internet.password }
    helm_repo
  end
end
