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
    user_id = @current_user_id
    release_id = playbacks_params
    @playback = Playback.new(release_id: release_id, user_id: user_id)

    if @playback.save
      render json: @playback, status: :ok
    else
      render json: @playback.errors, status: :unprocessable_entity
    end
  end

  private
  def playbacks_params
    params.require(:release_id)
  end
end
