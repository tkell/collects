class AnnotationsController < ApplicationController
  before_action :authenticate_user

  def index
    release = Release.joins(collection: :user)
      .where(users: { id: @current_user_id }, id: params[:release_id])
      .first
    return render json: { error: "Release not found" }, status: :not_found if release.nil?

    render json: release.annotations
  end

  def create
    release = Release.joins(collection: :user)
      .where(users: { id: @current_user_id }, id: params[:release_id])
      .first
    return render json: { error: "Release not found" }, status: :not_found if release.nil?

    annotation_type = annotation_params[:annotation_type]
    body = annotation_params[:body]
    bodies = (annotation_type == 'freeform') ? [body] : body.downcase.split(',').map(&:strip).reject(&:empty?)

    created = bodies.map do |b|
      Annotation.create!(release_id: release.id, annotation_type: annotation_type, body: b, user_id: @current_user_id)
    end

    release.increment!(:points)
    render json: created
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy
    annotation = Annotation.joins(release: { collection: :user })
      .where(users: { id: @current_user_id }, id: params[:id])
      .first
    return render json: { error: "Annotation not found" }, status: :not_found if annotation.nil?

    annotation.destroy
    render json: { id: params[:id].to_i }
  end

  private

  def annotation_params
    params.permit(:release_id, :body, :annotation_type)
  end
end
