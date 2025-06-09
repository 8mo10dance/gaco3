# frozen_string_literal: true

CarrierWave.configure do |config|
  if Rails.env.test?
    config.storage = :file
    config.cache_storage = :file
    config.root = Rails.root.join('tmp')
  else
    config.storage = :fog
    config.cache_storage = :fog
    config.fog_directory = Settings.aws.s3.bucket
    config.fog_credentials = {
      provider: 'AWS',
      region: Settings.aws.region,
      aws_access_key_id: ENV.fetch('AWS_ACCESS_KEY_ID'),
      aws_secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY'),
      endpoint: Settings.aws.endpoint,
      path_style: true
    }
  end
end
