class CollectionsController < ApplicationController
  def index
    @collections = Collection.all
  end

  def show
    @collection = Collection.find(params[:id])
    if params.has_key?(:serve_json)
      render json: @collection.items
    end
  end
end
