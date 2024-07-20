class PlaybacksController < ApplicationController
  def new
    @playback = Playback.new
  end

  def create
    @playback = Playback.new(params[:playback])

    if @playback.save
      render json: @playback, status: :ok
    else
      render json: @playback.errors, status: :unprocessable_entity
    end
  end
end
