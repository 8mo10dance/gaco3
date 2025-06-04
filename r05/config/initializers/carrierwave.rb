CarrierWave.configure do |config|
  config.storage          = :aws
  config.aws_bucket       = ENV.fetch('AWS_S3_BUCKET') { 'my-bucket' }
  config.aws_acl          = 'public-read'
  config.aws_credentials  = {
    access_key_id:     ENV.fetch('AWS_ACCESS_KEY_ID', 'dummy'),
    secret_access_key: ENV.fetch('AWS_SECRET_ACCESS_KEY', 'dummy'),
    region:            ENV.fetch('AWS_REGION', 'us-east-1')
  }
end
