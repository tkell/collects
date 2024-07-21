class AnnotationsController < ApplicationController
  before_action :authenticate_user

  # per-release
  def index
    @release = Release.where(id: params['release_id']).includes(:tracks).first
    @annotations = Annotation.where(release_id: @release.id)
  end

  def new
    @annotation = Annotation.new
  end

  def create
    @release_id = params['release_id']
    @annotation_type = params['annotation_type'].to_i
    @body = params['body']
    user_id = @current_user_id
    @annotation = Annotation.new(release_id: @release_id, annotation_type: @annotation_type, body: @body, user_id: user_id)

    if @annotation.save
      redirect_to action: "index"
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def annotation_params
    params.permit(:release_id, :body, :annotation_type)
  end
end
