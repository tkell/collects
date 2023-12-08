class CollectionsController < ApplicationController
  def index
    @collections = Collection.all
  end

  def show
    @collection = Collection.includes(items: :tracks).find(params[:id])
    if params.has_key?(:serve_json)
      render json: @collection.items.includes(:tracks)
    end
  end
end
