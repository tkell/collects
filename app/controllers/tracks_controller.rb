class TracksController < ApplicationController
  before_action :authenticate_user
  before_action :set_track, only: [:show, :update, :destroy]

  def index
    release = Release.joins(collection: :user)
      .where(users: { id: @current_user_id }, id: params[:release_id])
      .first

    if release.nil?
      render json: { error: "Release not found" }, status: :not_found
      return
    end

    render json: release.tracks
  end

  def show
    render json: @track
  end

  def update
    if @track.update(track_params)
      render json: @track
    else
      render json: { error: @track.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @track.destroy
    render json: { message: "Track deleted successfully" }, status: :ok
  end

  private

  def set_track
    @track = Track.joins(release: { collection: :user })
      .where(users: { id: @current_user_id }, tracks: { id: params[:id] })
      .first

    render json: { error: "Track not found" }, status: :not_found if @track.nil?
  end

  def track_params
    params
      .permit(:id, :release_id, :title, :position, :media_link, :external_id, :purchase_date)
      .except(:id, :release_id)
  end
end
