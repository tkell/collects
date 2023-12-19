class CollectionsController < ApplicationController
  def index
    @collections = Collection.all
  end

  def show
    @collection = Collection.includes(releases: :tracks).find(params[:id])
    if params.has_key?(:serve_json)

      p = tessellates_params
      filter_string = "%" + Release.sanitize_sql_like(p[:filter_string]) + "%"
      render json: @collection.releases
        .where("artist LIKE :search_string OR title LIKE :search_string OR label LIKE :search_string", {search_string: filter_string})
        .limit(p[:limit])
        .offset(p[:offset])
        .includes(:tracks)
    end
  end

  private

  def tessellates_params
    params.permit(:id, :serve_json, :limit, :offset, :filter_string).with_defaults(limit: 100, offset: 0, filter_string: "")
  end
end
