FactoryBot.define do
  factory :upload do
    sequence(:name) { |n| "DummyUpload#{n}" }
    size { "10 KB" }
    is_public { true }
    sequence(:file_path) { |n| "./public/dummy#{n}.txt" }
    content_type { "text/plain" }
    association :user
  end
end
