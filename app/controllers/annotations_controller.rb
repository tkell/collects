class AnnotationsController < ApplicationController
  # per-release
  def index
    @release = Release.where(id: params['release_id']).includes(:tracks).first
    @annotations = Annotation.where(release_id: @release.id)
  end

  def new
    @annotation = Annotation.new
  end

  def create
    @annotation = Annotation.new(annotation_params)

    if @annotation.save
      redirect_to @article
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def annotation_params
    params.require(:annotation).permit(:release_id, :user_id, :body, :type)
  end
end
