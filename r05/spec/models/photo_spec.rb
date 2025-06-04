require 'rails_helper'

RSpec.describe Photo, type: :model do
  it 'mounts ImageUploader on :image' do
    photo = described_class.new
    expect(photo).to respond_to(:image)
  end
end
