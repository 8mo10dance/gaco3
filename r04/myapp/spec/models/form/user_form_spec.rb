require 'rails_helper'

RSpec.describe Form::UserForm, type: :model do
  let(:user_form) { described_class.new(user_form_params) }

  describe '#save' do
    let(:user_form_params) do
      {
        name: 'dummy',
        avatar: Rack::Test::UploadedFile.new(Rails.root.join('spec/fixtures/files/test_image.jpg'), 'image/jpeg'),
      }
    end

    it { expect(user_form.save).to be_truthy }

    it { expect { user_form.save }.to change(User, :count).by 1 }
  end
end
