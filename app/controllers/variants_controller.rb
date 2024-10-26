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

    # Step 1: convert
    begin
      jpg_image = convert_to_jpg(variant_params[:img])
      small_image = make_small_image(jpg_image, 350)
      colors = Miro::DominantColors.new(small_image.path)
    rescue Exception => _
      puts("failed to convert image for release #{params[:release_id]}")
      render :new, status: :unprocessable_entity
    end

    # Step 2: save the variant
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

    # Step 3: upload the images
    begin
      bucket = create_bucket_handle(
        "collects-416256",
        "/Users/thor/Desktop/collects-416256-gcs-uploader-pk.json",
        "collects-images"
      )
      img_name, small_img_name = image_names(@release.external_id, @variant.id)
      bucket.create_file(jpg_image.path, img_name)
      bucket.create_file(small_image.path, small_img_name)
    rescue Exception => _
      puts("failed to upload images for release #{params[:release_id]} and variant #{@variant.id}")
      @variant.destroy
      if bucket && bucket.file(img_name)
        bucket.delete_file(img_name)
      end
      if bucket && bucket.file(small_img_name)
        bucket.delete_file(small_img_name)
      end
      render :new, status: :unprocessable_entity
    end

    begin
      new_image_path = "https://storage.googleapis.com/collects-images/#{@release.external_id}-v#{@variant.id}"
      @variant.update(image_path: new_image_path)
      @variant.save!
    rescue ActiveRecord::RecordInvalid => _
      @variant.destroy
      delete_image(bucket, image_name)
      delete_image(bucket, small_image_name)
      render :new, status: :unprocessable_entity
    end

    begin
      @release = Release.find(params[:release_id])
      @release.variants << @variant
      @release.current_variant_id = @variant.id
      @release.points -= variant_cost
      @release.points_spent += variant_cost
      @release.save
      redirect_to action: "index"
    rescue ActiveRecord::RecordInvalid => _
      @variant.destroy
      delete_image(bucket, image_name)
      delete_image(bucket, small_image_name)
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

    img_name, small_img_name = image_names(@release.external_id, @variant.id)
    bucket = create_bucket_handle(
      "collects-416256",
      "/Users/thor/Desktop/collects-416256-gcs-uploader-pk.json",
      "collects-images"
    )
    delete_image(bucket, img_name)
    delete_image(bucket, small_img_name)

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

  def guard_release_owns_variant
    if !@release.variants.include?(@variant)
      redirect_to action: "index"
      return
    end
  end

  def image_names(release_id, variant_id)
    image_name = "#{release_id}-v#{variant_id}.jpg"
    small_image_name = "#{release_id}-v#{variant_id}-small.jpg"

    return image_name, small_image_name
  end

  # Image things
  def convert_to_jpg(img_data)
    jpg_image = ImageProcessing::MiniMagick
      .source(img_data.path)
      .format("jpg")
      .call

    return jpg_image
  end

  def make_small_image(img_data, size)
    small_image = ImageProcessing::MiniMagick
      .source(img_data.path)
      .resize_to_limit(size, size)
      .call

    return small_image
  end


  # GCS things
  def create_bucket_handle(project_id, credentials_loc, bucket_name)
    storage = Google::Cloud::Storage.new(
      project_id: "collects-416256",
      credentials: "/Users/thor/Desktop/collects-416256-gcs-uploader-pk.json"
    )
    return storage.bucket("collects-images")
  end

  def delete_image(bucket, image_name)
    image_file = bucket.file(image_name)
    image_file.delete
  end
end
