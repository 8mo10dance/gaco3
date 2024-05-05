# frozen_string_literal: true

FactoryBot.define do
  factory :post do
    association :user

    content { Faker::Lorem.paragraph }
    image { Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test_image.jpg').to_s) }
  end
end
