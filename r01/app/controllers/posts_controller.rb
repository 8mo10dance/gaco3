class PostsController < ApplicationController
  before_action :set_user, only: %i[index new create]
  before_action :set_post, only: %i[show edit update destroy]

  def index
    @posts = @user.posts
  end

  def new
    @post = @user.posts.build
  end

  def create
    @post = @user.posts.build(post_params)
    return render :new if @post.invalid?

    @post.save!
    redirect_to post_path(@post)
  end

  def show
  end

  def edit
  end

  def update
    @post.attributes = post_params
    return render :edit if @post.invalid?

    @post.save!
    redirect_to post_path(@post)
  end

  def destroy
    @user = @post.user
    @post.destroy!
    redirect_to user_posts_path(@user)
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    def set_user
      @user = User.find(params[:user_id])
    end

    # Only allow a list of trusted parameters through.
    def post_params
      params.require(:post).permit(:content, :image)
    end
end
