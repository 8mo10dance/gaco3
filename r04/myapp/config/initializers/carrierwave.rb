# frozen_string_literal: true

CarrierWave.configure do |config|
  config.storage = :aws
  config.cache_storage = :aws

  config.aws_bucket = 'mybucket'
  config.aws_acl    = 'public-read'
end
