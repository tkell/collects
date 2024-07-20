class PlaybacksController < ApplicationController
  before_action :authenticate_user

  def index
    @playbacks = Playback.all
    render json: @playbacks, status: :ok
  end

  def new
    @playback = Playback.new
  end

  def create
    release_id = params[:playback][:release_id]
    @current_user = User.find(@current_user_id)
    user_id = current_user.id
    @playback = Playback.new(release_id: release_id, user_id: user_id)

    if @playback.save
      render json: @playback, status: :ok
    else
      render json: @playback.errors, status: :unprocessable_entity
    end
  end
end
