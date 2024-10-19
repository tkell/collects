class VariantsController < ApplicationController

  # per-release
  def index
    @release = Release.find(params[:release_id])
    @variants = Variant.where(release_id: @release.id)
    if @release.collection_id == 1 || @release.collection_id == 3
      @collection_name = 'digital'
    else
      @collection_name = 'vinyl'
    end

  end

  def show
    @variant = Variant.find(params[:id])
    @release = Release.find(@variant.release_id)
  end

  def new
    @variant = Variant.new
  end

  def create
    variant_cost = 1
    @release = Release.find(params[:release_id])

    img_data = variant_params[:img]
    processed_image = ImageProcessing::MiniMagick
      .source(img_data.path)
      .resize_to_limit(350, 350)
      .call

    colors = Miro::DominantColors.new(processed_image.path)
    puts(colors.to_hex.slice(0, 4))

    # it costs 1 point!
    if @release.points < variant_cost
      redirect_to action: "index"
      puts("not enough points, exiting")
      return
    end


    @variant = Variant.new(variant_params)
    if @variant.save
      @release = Release.find(params[:release_id])
      @release.variants << @variant
      @release.current_variant_id = @variant.id
      @release.points -= variant_cost
      @release.points_spent += variant_cost
      @release.save

      redirect_to action: "index"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # will need some image stuff here / remove it from hosting, etc
    # also make sure we can't destroy the only remaining variant / reassign current
    # ... should this even be possible?
    @variant = Variant.find(params[:id])
    @variant.destroy

    redirect_to action: "index"
  end

  private

  def variant_params
    params.permit(:release_id, :img, :commit)
  end
end
