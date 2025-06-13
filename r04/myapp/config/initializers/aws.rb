# frozen_string_literal: true

Aws.config.update(
  access_key_id: 'dummy',
  secret_access_key: 'dummy',
  region: 'ap-northeast-1',
  endpoint: 'http://localhost.localstack.cloud:4566',
  s3: {
    force_path_style: true,
  },
)
