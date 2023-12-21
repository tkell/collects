class CollectionsController < ApplicationController
  def index
    @collections = Collection.all
  end

  def show
    if params.has_key?(:serve_json)
      p = tessellates_params
      data = Collection.find(params[:id]).releases

      if p[:folder]
        data = data.where(folder: p[:folder])
      end
      if p[:filter_string]
        filter_string = "%" + Release.sanitize_sql_like(p[:filter_string]) + "%"
        data = data
          .where("artist LIKE :search_string OR title LIKE :search_string OR label LIKE :search_string", {search_string: filter_string})
      end

      data = data
        .limit(p[:limit])
        .offset(p[:offset])
        .includes(:tracks)

      render json: data
    else
      @collection = Collection.includes(releases: :tracks).find(params[:id])
    end

  end

  private

  def tessellates_params
    params
      .permit(:id, :serve_json, :limit, :offset, :filter_string, :folder)
      .with_defaults(limit: 100, offset: 0, filter_string: nil, folder: nil)
  end
end
