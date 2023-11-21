class GardensController < ApplicationController
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
      ## OK, we're close, we need to fix this redirect, but nbd!

      redirect_to @garden
    else
      puts(@garden.errors.full_messages)
      render :new, status: :unprocessable_entity
    end
  end

  private

  def garden_params
    params.require(:garden).permit(:name)
  end
end
