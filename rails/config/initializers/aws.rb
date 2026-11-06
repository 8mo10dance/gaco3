# frozen_string_literal: true

Aws.config.update(
  access_key_id: 'dummy',
  secret_access_key: 'dummy',
  region: 'ap-northeast-1',
  endpoint: 'http://localhost.floci.io:4566',
  s3: {
    force_path_style: true,
  },
)
