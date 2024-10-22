require "google/cloud/storage"

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
    variant_cost = -1 # heh
    @release = Release.find(params[:release_id])

    # Step 0:  check if we have enough points
    if @release.points < variant_cost
      redirect_to action: "index"
      puts("not enough points, exiting")
      render :new, status: :unprocessable_entity
    end

    # Step 1:  convert.  If we fail, get out
    img_data = variant_params[:img]
    jpg_image = ImageProcessing::MiniMagick
      .source(img_data.path)
      .format("jpg")
      .call

    small_image = ImageProcessing::MiniMagick
      .source(jpg_image.path)
      .resize_to_limit(350, 350)
      .call
    colors = Miro::DominantColors.new(small_image.path)

    # Step 2:  save the variant.  If we fail, get out
    variant_data = {
      release_id: @release.id,
      colors: colors.to_hex.slice(0, 2),
      image_path: "temp"
    }

    begin
      @variant = Variant.new(variant_data)
      @variant.save!
    rescue ActiveRecord::RecordInvalid => _
      render :new, status: :unprocessable_entity
    end


    # Step 3:  upload the images.  If we fail, get out _and_ delete both the variant and the images on GCS
    new_image_path = "https://storage.googleapis.com/collects-images/#{@release.external_id}-v#{@variant.id}"
    img_ext = File.extname(img_data.tempfile.path)
    image_name = "#{@release.external_id}-v#{@variant.id}#{img_ext}"
    small_image_name = "#{@release.external_id}-v#{@variant.id}-small#{img_ext}"

    storage = Google::Cloud::Storage.new(
      project_id: "collects-416256",
      credentials: "/Users/thor/Desktop/collects-416256-gcs-uploader-pk.json"
    )
    bucket = storage.bucket("collects-images")

    bucket.create_file(jpg_image.path, image_name)
    bucket.create_file(small_image.path, small_image_name)

    begin
      @variant.update(image_path: new_image_path)
      @variant.save!
      @release = Release.find(params[:release_id])
      @release.variants << @variant
      @release.current_variant_id = @variant.id
      @release.points -= variant_cost
      @release.points_spent += variant_cost
      @release.save
      redirect_to action: "index"
    rescue ActiveRecord::RecordInvalid => _
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
