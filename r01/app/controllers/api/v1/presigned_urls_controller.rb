class Api::V1::PresignedUrlsController < ApplicationController
  def show
    presigned_url = get_presigned_url("#{base_dir}/#{params[:filename]}", content_type: params[:content_type])
    render json: { url: presigned_url }
  end

  private

  def get_presigned_url(object_key, **attrs)
    url = bucket.object(object_key).presigned_url(:put, attrs)
    URI(url)
  end

  def bucket
    @bucket ||=
      Aws::S3::Bucket.new(
        Settings.aws.s3.bucket,
        region: Settings.aws.region,
        endpoint: 'http://localhost:4566',
        force_path_style: true
      )
  end

  def base_dir
    'tmp_uploads'
  end
end
