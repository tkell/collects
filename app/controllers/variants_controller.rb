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

  def guard_release_owns_variant
    if !@release.variants.include?(@variant)
      redirect_to action: "index"
      return 
    end


  def show
    @variant = Variant.find(params[:id])
    @release = Release.find(@variant.release_id)
    guard_release_owns_variant
  end

  def new
    @variant = Variant.new
  end

  def update
    @release = Release.find(params[:release_id])
    @variant = Variant.find(params[:id])
    guard_release_owns_variant

    @release.current_variant_id = @variant.id
    @release.save

    redirect_to action: "index"
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
      image_path: "temp",
      name: variant_params[:name],
    }

    begin
      @variant = Variant.new(variant_data)
      @variant.is_standard = false
      @variant.save!
    rescue ActiveRecord::RecordInvalid => _
      render :new, status: :unprocessable_entity
    end


    # Step 3:  upload the images.  If we fail, get out _and_ delete both the variant and the images on GCS
    new_image_path = "https://storage.googleapis.com/collects-images/#{@release.external_id}-v#{@variant.id}"
    img_ext = File.extname(jpg_image.path)
    image_name = "#{@release.external_id}-v#{@variant.id}.jpg"
    small_image_name = "#{@release.external_id}-v#{@variant.id}-small.jpg"

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
    @release = Release.find(params[:release_id])
    @variant = Variant.find(params[:id])

    if @variant.id == @release.current_variant_id || @release.variants.length == 1 || @variant.is_standard
      redirect_to action: "index"
      return
    end

    # delete the file first!
    storage = Google::Cloud::Storage.new(
      project_id: "collects-416256",
      credentials: "/Users/thor/Desktop/collects-416256-gcs-uploader-pk.json"
    )
    bucket = storage.bucket("collects-images")
    image_name = "#{@release.external_id}-v#{@variant.id}.jpg"
    small_image_name = "#{@release.external_id}-v#{@variant.id}-small.jpg"

    image_file = bucket.file(image_name)
    image_file.delete
    small_image_file = bucket.file(small_image_name)
    small_image_file.delete

    @release.current_variant_id = nil
    @release.save
    @variant.destroy
    @release.variants.delete(@variant)
    @release.current_variant_id = @release.variants.last.id
    @release.save

    redirect_to action: "index"
  end

  private

  def variant_params
    params.permit(:release_id, :img, :name, :commit)
  end
end
