FactoryBot.define do
  factory :post do
    association :user

    content { Faker::Lorem.paragraph }
    image { Rack::Test::UploadedFile.new(File.join(Rails.root, 'spec/fixtures/files/test_image.jpg')) }
  end
end
