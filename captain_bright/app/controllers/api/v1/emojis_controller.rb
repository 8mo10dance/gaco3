class Api::V1::EmojisController < ApplicationController
  before_action :set_emoji, only: [:show, :update, :destroy]

  # GET /api/v1/emojis
  def index
    @emojis = Emoji.all
    render json: @emojis
  end

  # GET /api/v1/emojis/1
  def show
    render json: @emoji
  end

  # POST /api/v1/emojis
  def create
    @emoji = Emoji.new(emoji_params)

    if @emoji.save
      render json: @emoji, status: :created, location: api_v1_emoji_url(@emoji)
    else
      render json: @emoji.errors, status: :unprocessable_entity
    end
  end

  # PATCH/PUT /api/v1/emojis/1
  def update
    if @emoji.update(emoji_params)
      render json: @emoji
    else
      render json: @emoji.errors, status: :unprocessable_entity
    end
  end

  # DELETE /api/v1/emojis/1
  def destroy
    @emoji.destroy
    head :no_content
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_emoji
      @emoji = Emoji.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def emoji_params
      params.require(:emoji).permit(:body)
    end
end
