class AnnotationsController < ApplicationController
  before_action :authenticate_user

  # per-release
  def index
    @release = Release.where(id: params['release_id']).includes(:tracks).first
    @annotations = Annotation.where(release_id: @release.id)

    if @release.collection_id == 1 || @release.collection_id == 3
      @collection_name = 'digital'
    else
      @collection_name = 'vinyl'
    end

    @annotations_by_type = {}
    @annotations.each do |annotation|
      if @annotations_by_type[annotation.annotation_type].nil?
        @annotations_by_type[annotation.annotation_type] = []
      end
      @annotations_by_type[annotation.annotation_type].push(annotation)
    end
  end

  def new
    @annotation = Annotation.new
  end

  def create
    @release_id = params['release_id']
    @annotation_type = params['annotation_type'].to_i
    @body = params['body']
    user_id = @current_user_id

    if @annotation_type != 3
      @body = @body.downcase
      @bodies = @body.split(',')
    else
      @bodies = [@body]
    end

    @bodies.each do |body|
      @annotation = Annotation.new(release_id: @release_id, annotation_type: @annotation_type, body: body.strip(), user_id: user_id)
      @annotation.save
    end

    if @annotation.save
      release = Release.find(@release_id)
      release.points += 1
      release.save
      redirect_to action: "index"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    @annotation = Annotation.find(params[:id])
    @annotation.destroy

    redirect_to action: "index"
  end


  private

  def annotation_params
    params.permit(:release_id, :body, :annotation_type)
  end
end
