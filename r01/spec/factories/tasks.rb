FactoryBot.define do
  factory :task do
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.paragraph }
  end
end
