class PhotosController < ApplicationController
  def create
    @photo = Photo.create!(photo_params)
    render json: { id: @photo.id, url: @photo.image.url }
  end

  private

  def photo_params
    params.require(:photo).permit(:image)
  end
end
