FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "DummyUser#{n}" }
    sequence(:email) { |n| "DummyUser#{n}@gmail.com" }
    password { "Password123" }
    password_confirmation { "Password123" }
  end
end
