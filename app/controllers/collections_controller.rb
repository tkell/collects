class CollectionsController < ApplicationController
  def index
    @collections = Collection.all
  end

  def show
    @collection = Collection.includes(releases: :tracks).find(params[:id])
    if params.has_key?(:serve_json)
      render json: @collection.releases.includes(:tracks)
    end
  end
end
