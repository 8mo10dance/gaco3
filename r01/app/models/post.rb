class Post < ApplicationRecord
  belongs_to :user

  attribute :image_path

  def set_image!
    move_to(image_path, "#{carrierwave_store_dir('image')}/#{image}")
    self.image = image
    save!
  end

  def image_url
    "http://localhost:4566/#{Settings.aws.s3.bucket}/#{carrierwave_store_dir('image')}/#{image}"
  end

  private

  def carrierwave_store_dir(mounted_as)
    "uploads/post/#{mounted_as}/#{id}"
  end

  def move_to(from_path, to_path)
    from_obj = bucket.object(from_path)
    to_obj = bucket.object(to_path)
    from_obj.copy_to(to_obj)
    from_obj.delete
  end

  def bucket
    @bucket ||=
      Aws::S3::Bucket.new(
        Settings.aws.s3.bucket,
        region: Settings.aws.region,
        endpoint: 'http://localstack:4566',
        force_path_style: true
      )
  end
end
