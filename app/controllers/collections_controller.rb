class CollectionsController < ApplicationController
  SORT_KEYS = {
    "a" => :artist,
    "t" => :title,
    "l" => :label,
    "y" => :release_year,
    "p" => 'purchase_date DESC'
  }

  def index
    authenticate_user
    @collections = @current_user.collections.order(:created_at)

    render json: @collections
  end

  def show
    authenticate_user

    p = tessellates_params
    name = params[:id]
    data = @current_user.collections.where('lower(name) = ?', name.downcase).first.releases
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

    if p[:purchase_date]
      if p[:purchase_date].include? "-"
        year_range = p[:purchase_date].split("-")
        start_year = year_range[0].strip.to_i
        end_year = year_range[1].strip.to_i
        start_date = "#{start_year}-01-01".to_date
        end_date = "#{end_year}-12-31".to_date
        data = data.where(purchase_date: start_date..end_date)
      else
        year = p[:purchase_date].strip.to_i
        start_date = "#{year}-01-01".to_date
        end_date = "#{year}-12-31".to_date
        data = data.where(purchase_date: start_date..end_date)
      end
    end

    if p[:filter]
      filter_string = "%" + Release.sanitize_sql_like(p[:filter]) + "%"
      data = data
        .where("artist ILIKE :search_string OR title ILIKE :search_string OR label ILIKE :search_string", {search_string: filter_string})
    end

    # We use the front-end's "random" sort and pick an offset here, if we're randomizing
    if p[:randomize]
      p[:sort] = p[:randomize]
      real_offset = (rand() * data.size).floor # SQL call to get the size of the data!
    else
      real_offset = p[:offset]
    end

    # see above, options are artist, title, label, release_year, purchase_date
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
      .offset(real_offset)
      .includes(:tracks)
      .joins("LEFT JOIN variants ON variants.release_id = releases.id AND variants.id = releases.current_variant_id")
      .includes(:variants)

    render json: data
  end

  def create
    authenticate_user
    return if performed?

    collection = Collection.new(name: collection_params[:name], user: @current_user, level:0 )
    unless collection.save
      render json: { error: collection.errors }, status: :unprocessable_entity
      return
    end

    if collection_params[:release_source] == 'json_file'
      release_source = RubyHashReleaseSource.new(collection: collection)
    else
      render json: { error: "Only JSON collections are currently supported!" }, status: :unprocessable_entity
      return
    end

    unless release_source.save
      collection.destroy
      render json: { error: release_source.errors }, status: :unprocessable_entity
      return
    end

    if params[:releases].present?
      release_source.raw_releases = params[:releases]
      release_source.import_releases('only_new', {})
    end

    render json: collection, status: :created
  rescue => e
    render json: { error: "Failed to create collection: #{e.message}" }, status: :unprocessable_entity
  end

  def update
    authenticate_user
    return if performed?

    id = collection_update_params[:id]
    collection = @current_user.collections.find(id)
    if collection.nil?
      render json: { error: "Collection not found" }, status: :not_found
      return
    end

    # will need to set up a switch based on release source type here
    overwrite_strategy = params.fetch(:overwrite_strategy, "only_new")
    release_source = collection.release_sources.first
    release_source.raw_releases = params[:releases] || []
    release_source.import_releases(overwrite_strategy, collection.releases.index_by(&:external_id)) do |release_data|
      ActionCable.server.broadcast("collection_import_#{collection.id}", release_data)
    end
    collection.reload
    ActionCable.server.broadcast("collection_import_#{collection.id}", { type: "done", level: collection.level })

    render json: collection
  rescue => e
    render json: { error: "Failed to update collection: #{e.message}" }, status: :unprocessable_entity
  end

  def destroy
    authenticate_user
    name = params[:id]
    collection = @current_user.collections.where('lower(name) = ?', name.downcase).first

    if collection.nil?
      render json: { error: "Collection not found" }, status: :not_found
      return
    end

    ActiveRecord::Base.transaction do
      collection.gardens.each do |garden|
        garden.garden_releases.destroy_all
        garden.destroy
      end
      collection.releases.destroy_all
      collection.destroy
    end

    render json: { message: "Collection deleted successfully" }, status: :ok
  rescue => e
    render json: { error: "Failed to delete collection: #{e.message}" }, status: :unprocessable_entity
  end

  private

  def collection_params
    params.permit(:name, :release_source)
  end

  def collection_update_params
    ## I hate this, there must be a way to generate them, hmm
    params.permit(:id, :overwrite_strategy, releases: [:id, :title, :artist, :label, :image_path, :year, :purchase_date, tracks: [:position, :title, :filepath]], collection: {})
  end

  def tessellates_params
    params
      .permit(:id, :serve_json, :limit, :offset, :filter, :folder, :release_year, :purchase_date, :sort, :randomize)
      .with_defaults(limit: 100, offset: 0, filter_string: nil, folder: nil, release_year: nil, purchase_date: nil, sort: nil, randomize: nil)
  end
end
