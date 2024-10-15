class VariantsController < ApplicationController
  def index
    @release = Release.find(params[:release_id])
    @variants = Variant.where(release_id: @release.id)
  end

  def show
    @variant = Variant.find(params[:id])
    @release = Release.find(@variant.release_id)
  end

  def new
    @variant = Variant.new
  end

  def create
    @release = Release.find(params[:release_id])
    @variant = Variant.new(variant_params)
    if @variant.save
      @release.variants << @variant
      @release.current_variant_id = @variant.id

      # subtract some points here??
      

      redirect_to @variant
    else
      render 'new'
    end
  end
end
