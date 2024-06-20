class CollectionsController < ApplicationController
  SORT_KEYS = {
    "a" => :artist,
    "t" => :title,
    "l" => :label,
    "y" => :release_year,
    "p" => 'purchase_date DESC'
  }

  def index
    @collections = Collection.all
  end

  def show
    if params.has_key?(:serve_json)
      p = tessellates_params
      collection_name = p[:id].capitalize
      data = Collection.where(name: collection_name).first.releases

      if p[:folder]
        data = data.where(folder: p[:folder])
      end
      # format is `1990 - 1999`, or `1990`
      if p[:release_year]
        if p[:release_year].include? "-"
          year_range = p[:release_year].split("-")
          start_year = year_range[0].strip.to_i
          end_year = year_range[1].strip.to_i
          data = data.where(release_year: start_year..end_year)
        else
          data = data.where(release_year: Integer(p[:release_year]))
        end

      end
      if p[:filter_string]
        filter_string = "%" + Release.sanitize_sql_like(p[:filter_string]) + "%"
        data = data
          .where("artist LIKE :search_string OR title LIKE :search_string OR label LIKE :search_string", {search_string: filter_string})
      end

      # see above, options are artist, title, label, release_year
      if p[:sort] && p[:sort].length > 0 && p[:sort].size < 5
        sort_args = []
        p[:sort].split("").each do |key|
          if SORT_KEYS.has_key?(key)
            sort_args << SORT_KEYS[key]
          end
        end
        data = data.order(*sort_args)
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
      .permit(:id, :serve_json, :limit, :offset, :filter_string, :folder, :release_year, :sort)
      .with_defaults(limit: 100, offset: 0, filter_string: nil, folder: nil, release_year: nil, sort: nil)
  end
end
