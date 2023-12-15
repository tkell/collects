class GardensController < ApplicationController
  MAX_ITEMS_PER_GARDEN = 28

  def index
    @gardens = Garden.all
  end

  def show
    @garden = Garden.find(params[:id])
  end

  def new
    @collection = Collection.find(params[:collection_id])
    @garden = @collection.gardens.new
  end

  def create
    @collection = Collection.find(params[:collection_id])
    @garden = @collection.gardens.create(garden_params)

    if @garden.save
      redirect_to collection_garden_path(@collection, @garden)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @collection = Collection.find(params[:collection_id])
    @garden = Garden.find(params[:id])
    safe_search_string = Release.sanitize_sql_like("#{params[:release_search]}") + "%"
    @searched_releases = Release.where("title LIKE ?", safe_search_string)

    @number_of_addable_releases = MAX_ITEMS_PER_GARDEN - @garden.releases.size
  end

  def update
    @collection = Collection.find(params[:collection_id])
    @garden = Garden.find(params[:id])

    if @garden.update(garden_params)
      redirect_to collection_garden_path(@collection, @garden)
    else
      puts(@garden.errors.full_messages)
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def garden_params
    params.require(:garden).permit(:name, garden_items_attributes: [:id, :release_id, :_destroy])
  end
end
