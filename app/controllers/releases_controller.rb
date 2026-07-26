class ReleasesController < ApplicationController
  before_action :authenticate_user
  before_action :set_release, only: [:show, :update, :destroy]

  def show
    render json: @release
  end

  def update
    if @release.update(release_params)
      render json: @release
    else
      render json: { error: @release.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @release.destroy
    render json: { message: "Release deleted successfully" }, status: :ok
  rescue => e
    render json: { error: "Failed to delete release: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def set_release
    @release = Release.joins(collection: :user)
      .where(users: { id: @current_user_id }, id: params[:id])
      .first

    render json: { error: "Release not found" }, status: :not_found if @release.nil?
  end

  def release_params
    params
      .permit(:id, :title, :artist, :label, :folder, :release_year, :purchase_date, :external_id)
      .except(:id)
  end
end
