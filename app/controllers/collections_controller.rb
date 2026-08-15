class CollectionsController < ApplicationController
  before_action :authenticate_user!


  def index
    @collections = @current_user.collections.order(:created_at)

    render json: @collections
  end

  def show
    p = tessellates_params
    name = params[:id]
    collection = @current_user.collections.where('lower(name) = ?', name.downcase).first
    data = collection.query_releases(p[:offset], p[:limit], p[:filter], p[:release_year], p[:purchase_date], p[:sort], p[:folder], p[:randomize])

    render json: data
  end

  def create
    collection = Collection.new(name: collection_params[:name], user: @current_user, level:0 )
    unless collection.save
      puts(collection.errors)
      render json: { error: collection.errors }, status: :unprocessable_content
      return
    end

    channel = "collection_import_#{collection_params[:import_token].presence || collection.id}"

    case collection_params[:release_source]
    when 'json_file'
      release_source = RubyHashReleaseSource.new(collection: collection)
      unless release_source.save
        collection.destroy
        render json: { error: release_source.errors }, status: :unprocessable_content
        return
      end
      if collection_params[:releases].present?
        release_source.raw_releases = collection_params[:releases]
        ActionCable.server.broadcast(channel, { type: "start", input_count: release_source.input_count, existing: 0 })
        release_source.import_releases('only_new', {}) do |release_data|
          ActionCable.server.broadcast(channel, release_data)
        end
        collection.reload
        ActionCable.server.broadcast(channel, { type: "done", level: collection.level })
      end

    when 'spotify_exportify_csv'
      release_source = SpotifyExportifyCsvReleaseSource.new(collection: collection)
      unless release_source.save
        collection.destroy
        render json: { error: release_source.errors }, status: :unprocessable_content
        return
      end
      if collection_params[:csv_content].present?
        release_source.raw_csv = collection_params[:csv_content]
        ActionCable.server.broadcast(channel, { type: "start", input_count: release_source.input_count, existing: 0 })
        release_source.import_releases('only_new', {}) do |release_data|
          ActionCable.server.broadcast(channel, release_data)
        end
        collection.reload
        ActionCable.server.broadcast(channel, { type: "done", level: collection.level })
      end

    when 'discogs_oauth'
      release_source = DiscogsOAuthReleaseSource.new(collection: collection)
      unless release_source.save
        collection.destroy
        render json: { error: release_source.errors }, status: :unprocessable_content
        return
      end
      # nothing is uploaded here - the release source pulls everything from
      # discogs using the tokens we stored when the user linked their account
      begin
        ActionCable.server.broadcast(channel, { type: "start", input_count: release_source.input_count, existing: 0 })
        release_source.import_releases('only_new', {}) do |release_data|
          ActionCable.server.broadcast(channel, release_data)
        end
      rescue DiscogsOAuthClient::Error => e
        collection.destroy
        ActionCable.server.broadcast(channel, { type: "error", message: e.message })
        render json: { error: e.message }, status: :unprocessable_content
        return
      end
      collection.reload
      ActionCable.server.broadcast(channel, { type: "done", level: collection.level })

    else
      collection.destroy
      render json: { error: "Unsupported release source" }, status: :unprocessable_content
      return
    end


    render json: collection, status: :created
  rescue => e
    puts(e)
    puts(e.backtrace.join("\n"))
    puts(e.message)
    render json: { error: "Failed to create collection: #{e.message}" }, status: :unprocessable_content
  end

  def update
    id = collection_update_params[:id]
    collection = @current_user.collections.find(id)
    if collection.nil?
      render json: { error: "Collection not found" }, status: :not_found
      return
    end

    overwrite_strategy = collection_update_params.fetch(:overwrite_strategy, "only_new")
    release_source = collection.release_sources.first

    case release_source
    when RubyHashReleaseSource
      release_source.raw_releases = collection_update_params[:releases] || []
    when SpotifyExportifyCsvReleaseSource
      release_source.raw_csv = collection_update_params[:csv_content] || ""
    when DiscogsOAuthReleaseSource
      # nothing to set up - it re-fetches from discogs itself
    else
      render json: { error: "Unsupported release source" }, status: :unprocessable_content
      return
    end

    current_releases = collection.releases.joins(:variants).pluck(:external_id, :colors).index_by {|r| r[0]}
    ActionCable.server.broadcast("collection_import_#{collection.id}", { type: "start", input_count: release_source.input_count, existing: current_releases.length})
    release_source.import_releases(overwrite_strategy, current_releases) do |release_data|
      ActionCable.server.broadcast("collection_import_#{collection.id}", release_data)
    end
    collection.reload
    ActionCable.server.broadcast("collection_import_#{collection.id}", { type: "done", level: collection.level })

    render json: collection
  rescue => e
    puts(e)
    puts(e.backtrace.join("\n"))
    puts(e.message)
    render json: { error: "Failed to update collection: #{e.message}" }, status: :unprocessable_content
  end

  def destroy
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
    render json: { error: "Failed to delete collection: #{e.message}" }, status: :unprocessable_content
  end

  private

  def collection_params
    params.permit(:name, :release_source, :import_token, :csv_content, releases: [:id, :title, :artist, :label, :image_path, :image_url, :image_url_small, :year, :purchase_date, tracks: [:position, :title, :filepath]] )
  end

  def collection_update_params
    params.permit(:id, :overwrite_strategy, :csv_content, releases: [:id, :title, :artist, :label, :image_path, :image_url, :image_url_small, :year, :purchase_date, tracks: [:position, :title, :filepath]] )
  end

  def tessellates_params
    params
      .permit(:id, :serve_json, :limit, :offset, :filter, :folder, :release_year, :purchase_date, :sort, :randomize)
      .with_defaults(limit: 100, offset: 0)
  end
end
