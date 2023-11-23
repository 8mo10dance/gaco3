require 'rails_helper'

RSpec.describe "Api::V1::PresignedUrls", type: :request do
  describe "GET /api/v1/presigned_url" do
    subject { get '/api/v1/presigned_url' }

    it { is_expected.to eq 200 }
  end
end
