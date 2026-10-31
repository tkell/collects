class FoldersController < ApplicationController
  before_action :authenticate_user
  before_action :set_folder, only: [:update, :destroy]

  def index
    collection = @current_user.collections
      .where('lower(name) = ?', params[:c].to_s.downcase)
      .first

    if collection.nil?
      render json: { error: "Collection not found" }, status: :not_found
      return
    end

    render json: collection.folders
  end

  def update
    if @folder.update(folder_params)
      render json: @folder
    else
      render json: { error: @folder.errors }, status: :unprocessable_content
    end
  end

  def destroy
    # needs to set a bunch of of release.folder_ids to nil
  end

  private

  def set_folder
    # scoped through the user's collections, so you can't touch other users' folders
    @folder = Folder.joins(:collection)
      .where(collections: { user_id: @current_user.id })
      .find(params[:id])
  end

  def folder_params
    params
      # name is read-only for now: renaming would break the folder filter and
      # re-imports, which both match releases to folders by name
      .permit(:id, :collection_id, :short_name)
      .except(:id, :collection_id)
  end
end
